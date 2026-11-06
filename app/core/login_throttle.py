"""Brute-force protection for the login endpoints.

Failed logins (401/403) are counted per client IP and login route over a sliding window; once the
limit is reached the route answers 429 until the window frees up. State is in memory, which fits
the single-instance deployment; a multi-instance setup would need a shared store (e.g. Redis).
"""
import time
from collections import defaultdict, deque

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

MAX_FAILURES = 20
WINDOW_SECONDS = 15 * 60


def client_ip(request: Request) -> str:
    # Render's proxy appends the address it saw: the right-most entry cannot be forged by the client.
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[-1].strip()
    return request.client.host if request.client else "unknown"


class LoginThrottle:
    def __init__(self, max_failures: int = MAX_FAILURES, window: float = WINDOW_SECONDS, clock=time.monotonic):
        self.max_failures = max_failures
        self.window = window
        self.clock = clock
        self._failures: dict[str, deque] = defaultdict(deque)

    def _prune(self, key: str) -> deque:
        entries = self._failures[key]
        limit = self.clock() - self.window
        while entries and entries[0] < limit:
            entries.popleft()
        if not entries:
            self._failures.pop(key, None)
            return deque()
        return entries

    def retry_after(self, key: str) -> int:
        """Seconds until the key may try again, 0 if it is not blocked."""
        entries = self._prune(key)
        if len(entries) < self.max_failures:
            return 0
        return max(1, int(entries[0] + self.window - self.clock()))

    def failure(self, key: str) -> None:
        self._prune(key)
        self._failures[key].append(self.clock())

    def success(self, key: str) -> None:
        self._failures.pop(key, None)


class LoginThrottleMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, throttle: LoginThrottle | None = None):
        super().__init__(app)
        self.throttle = throttle or LoginThrottle()

    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        if request.method != "POST" or "/auth/" not in path or not path.endswith("/login"):
            return await call_next(request)
        key = f"{client_ip(request)}|{path}"
        wait = self.throttle.retry_after(key)
        if wait:
            return JSONResponse(
                status_code=429,
                content={"detail": "Too many failed login attempts. Try again later."},
                headers={"Retry-After": str(wait)},
            )
        response = await call_next(request)
        if response.status_code in (401, 403):
            self.throttle.failure(key)
        elif response.status_code < 400:
            self.throttle.success(key)
        return response

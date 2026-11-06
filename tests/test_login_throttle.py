from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

from app.core.login_throttle import LoginThrottle, LoginThrottleMiddleware


class FakeClock:
    def __init__(self):
        self.now = 0.0

    def __call__(self):
        return self.now


def test_throttle_blocks_after_limit_and_frees_after_window():
    clock = FakeClock()
    throttle = LoginThrottle(max_failures=3, window=60, clock=clock)
    for _ in range(3):
        assert throttle.retry_after("k") == 0
        throttle.failure("k")
    assert throttle.retry_after("k") == 60
    clock.now = 30
    assert throttle.retry_after("k") == 30
    clock.now = 61
    assert throttle.retry_after("k") == 0


def test_success_resets_the_counter():
    throttle = LoginThrottle(max_failures=2, window=60, clock=FakeClock())
    throttle.failure("k")
    throttle.success("k")
    throttle.failure("k")
    assert throttle.retry_after("k") == 0


def _app(throttle):
    app = FastAPI()
    app.add_middleware(LoginThrottleMiddleware, throttle=throttle)

    @app.post("/api/v1/auth/teacher/login")
    async def login(ok: bool = False):
        if not ok:
            raise HTTPException(status_code=401, detail="bad")
        return {"access_token": "x"}

    @app.post("/api/v1/students/")
    async def other():
        raise HTTPException(status_code=401, detail="bad")

    return app


def test_middleware_returns_429_only_on_login_routes():
    client = TestClient(_app(LoginThrottle(max_failures=2, window=60, clock=FakeClock())))
    assert client.post("/api/v1/auth/teacher/login").status_code == 401
    assert client.post("/api/v1/auth/teacher/login").status_code == 401
    blocked = client.post("/api/v1/auth/teacher/login?ok=true")
    assert blocked.status_code == 429 and blocked.headers["retry-after"] == "60"
    # other routes are never throttled
    for _ in range(5):
        assert client.post("/api/v1/students/").status_code == 401


def test_forwarded_for_uses_the_proxy_entry():
    client = TestClient(_app(LoginThrottle(max_failures=1, window=60, clock=FakeClock())))
    client.post("/api/v1/auth/teacher/login", headers={"X-Forwarded-For": "6.6.6.6, 1.1.1.1"})
    # a different forged first entry does not escape the block of the real (right-most) address
    assert client.post("/api/v1/auth/teacher/login", headers={"X-Forwarded-For": "7.7.7.7, 1.1.1.1"}).status_code == 429
    assert client.post("/api/v1/auth/teacher/login", headers={"X-Forwarded-For": "2.2.2.2"}).status_code == 401

import re

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, ORJSONResponse
from contextlib import asynccontextmanager
import logging
from fastapi import Depends
from sqlalchemy import text
from sqlalchemy.exc import DBAPIError, IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.login_throttle import LoginThrottleMiddleware
from app.db.session import engine, get_db
from app.api.v1.routes import register_routes


# Configure logging
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app : FastAPI):
    logger.info("🚀 Starting Ahl Quran School Management API...")
    yield
    await engine.dispose()
    logger.info("Application shutdown complete")


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend API for Ahl El Quran School Management System",
    version="1.0.0",
    lifespan=lifespan,
    default_response_class=ORJSONResponse
)

# Only this project's Vercel deployments (production + previews), not every *.vercel.app site.
VERCEL_ORIGIN = re.compile(r"^https://ahl-el-quran[a-z0-9-]*\.vercel\.app$")


@app.exception_handler(Exception)
async def unhandled_error(request: Request, exc: Exception) -> JSONResponse:
    """A crash is answered outside the CORS middleware, so browsers would report it as a CORS failure."""
    logger.exception("Unhandled error on %s %s", request.method, request.url.path, exc_info=exc)
    response = JSONResponse(status_code=500, content={"detail": "Internal server error"})
    origin = request.headers.get("origin")
    if origin and (origin in settings.CORS_ORIGINS or VERCEL_ORIGIN.match(origin)):
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Credentials"] = "true"
        response.headers["Vary"] = "Origin"
    return response


BAD_VALUE_ERROR = re.compile(r"DataError|InvalidRowCount|CharacterNotInRepertoire|UntranslatableCharacter")
MAX_DATABASE_ID = 2147483647


class RejectImpossibleIds:
    """A number too large to be an id cannot match anything, even in routes that catch every error themselves."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http" and any(part.isdigit() and int(part) > MAX_DATABASE_ID for part in scope["path"].split("/")):
            await JSONResponse(status_code=404, content={"detail": "Not found"})(scope, receive, send)
            return
        await self.app(scope, receive, send)


@app.exception_handler(IntegrityError)
async def duplicate_or_conflict(request: Request, exc: IntegrityError) -> JSONResponse:
    """Two requests racing for the same unique value, or a record that is still referenced."""
    logger.warning("Integrity error on %s %s: %s", request.method, request.url.path, exc.orig)
    return JSONResponse(status_code=409, content={"detail": "This record already exists or is still in use"})


@app.exception_handler(DBAPIError)
async def value_rejected_by_database(request: Request, exc: DBAPIError) -> JSONResponse:
    """Values the database cannot store (a number too large, a NUL character) are bad input, not a crash."""
    if BAD_VALUE_ERROR.search(str(exc)):
        return JSONResponse(status_code=422, content={"detail": "Invalid value"})
    logger.exception("Database error on %s %s", request.method, request.url.path, exc_info=exc)
    return await unhandled_error(request, exc)


app.add_middleware(RejectImpossibleIds)

# Login brute-force protection (inner; CORS is added after so it wraps the 429 responses too)
app.add_middleware(LoginThrottleMiddleware)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=VERCEL_ORIGIN.pattern,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_routes(app)

@app.get("/health/live", tags=["health"])
async def liveness():
    return {"status": "ok"}


@app.get("/health/ready", tags=["health"])
async def readiness(db: AsyncSession = Depends(get_db)):
    await db.execute(text("SELECT 1"))
    return {"status": "ready"}

@app.get("/")
async def root():
    return {
        "message": "Welcome to Ahl Quran School Management API",
        "version": "1.0.0",
    }

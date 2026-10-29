from fastapi import FastAPI, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import ORJSONResponse
from contextlib import asynccontextmanager
import logging
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
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

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=r"^https:\/\/.*\.vercel\.app$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

TRAILING_SLASH_PREFIXES = {
    f"{settings.API_V1_PREFIX}/students",
    f"{settings.API_V1_PREFIX}/teacher",
    f"{settings.API_V1_PREFIX}/supervisor",
    f"{settings.API_V1_PREFIX}/lectures",
    f"{settings.API_V1_PREFIX}/guardians",
    f"{settings.API_V1_PREFIX}/messages",
    f"{settings.API_V1_PREFIX}/admin",
    f"{settings.API_V1_PREFIX}/president",
}

@app.middleware("http")
async def fix_proxy_redirects(request: Request, call_next):
    if request.url.path in TRAILING_SLASH_PREFIXES:
        request.scope["path"] = request.url.path + "/"
    response = await call_next(request)
    if response.status_code in (301, 302, 307, 308) and "location" in response.headers:
        loc = response.headers["location"]
        if loc.startswith("http://"):
            response.headers["location"] = loc.replace("http://", "https://", 1)
    return response

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

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import ORJSONResponse
from contextlib import asynccontextmanager
import logging

from app.core.config import settings
from app.db.init_db import init_db
from app.api.v1.routes import register_routes


# Configure logging
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app : FastAPI):
    # Startup
    logger.info("🚀 Starting Ahl Quran School Management API...")
    try:
        await init_db()
        logger.info("✅ Application startup complete")
    except Exception as e:
        logger.error(f"❌ Startup failed: {str(e)}")
        raise
    yield
    logger.info("👋 Shutting down application...")


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
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_routes(app)

@app.get("/")
async def root():
    return {
        "message": "Welcome to Ahl Quran School Management API",
        "version": "1.0.0",
    }

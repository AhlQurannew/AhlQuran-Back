from app.core.config import settings

from .auth import authRouter
from .admin import adminRouter
from .president import presidentRouter
from .supervisor import supervisorRouter
from .teacher import teacherRouter
from .student import studentRouter
from .lectures import lectureRouter
from .guardian import guardianRouter
from .messages import messageRouter
from .ws_messages import ws_router

def register_routes(app):
    routes = [
        (authRouter, "/auth", ["Authentication"]),
        (adminRouter, "/admin", ["Admin"]),
        (presidentRouter, "/president", ["President"]),
        (supervisorRouter, "/supervisor", ["Supervisor"]),
        (teacherRouter, "/teacher", ["Teacher"]),
        (studentRouter, "/students", ["Students"]),
        (lectureRouter, "/lectures", ["Lectures"]),
        (guardianRouter, "/guardians", ["Guardians"]),
        (messageRouter, "/messages", ["Messages"]),
    ]

    for router, prefix, tags in routes:
        app.include_router(
            router,
            prefix=f"{settings.API_V1_PREFIX}{prefix}",
            tags=tags
        )

    # Register WebSocket router directly on app
    app.include_router(ws_router, tags=["WebSocket"])

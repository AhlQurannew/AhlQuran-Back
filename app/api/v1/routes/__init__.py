from app.core.config import settings

from .auth import authRouter
from .admin import adminRouter
from .analytics import analyticsRouter
from .president import presidentRouter
from .supervisor import supervisorRouter
from .teacher import teacherRouter
from .student import studentRouter
from .lectures import lectureRouter
from .guardian import guardianRouter
from .messages import messageRouter
from .notes import notesRouter
from .site import siteRouter
from .specialities import specialityRouter
from .exams import examRouter
from .inspectors import inspectorRouter
from .ws_messages import ws_router

def register_routes(app):
    routes = [
        (authRouter, "/auth", ["Authentication"]),
        (adminRouter, "/admin", ["Admin"]),
        (analyticsRouter, "/admin/analytics", ["Admin analytics"]),
        (inspectorRouter, "/admin/inspectors", ["Inspectors"]),
        (presidentRouter, "/president", ["President"]),
        (supervisorRouter, "/supervisor", ["Supervisor"]),
        (teacherRouter, "/teacher", ["Teacher"]),
        (studentRouter, "/students", ["Students"]),
        (lectureRouter, "/lectures", ["Lectures"]),
        (guardianRouter, "/guardians", ["Guardians"]),
        (messageRouter, "/messages", ["Messages"]),
        (notesRouter, "/notes", ["Teacher notes"]),
        (siteRouter, "/site", ["Site"]),
        (specialityRouter, "/specialities", ["Specialities"]),
        (examRouter, "/exams", ["Exams"]),
    ]

    for router, prefix, tags in routes:
        app.include_router(
            router,
            prefix=f"{settings.API_V1_PREFIX}{prefix}",
            tags=tags
        )

    # Register WebSocket router directly on app
    app.include_router(ws_router, tags=["WebSocket"])

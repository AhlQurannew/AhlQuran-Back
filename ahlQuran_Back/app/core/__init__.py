# Don't import get_db here - it should only be imported where needed
# from app.core.dependencies import get_db  # ← REMOVE THIS

# You can keep these if they don't cause circular imports
# from app.core.config import settings
# from app.core.security import get_password_hash, verify_password
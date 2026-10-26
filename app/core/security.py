from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import settings
import logging
import hmac

logger = logging.getLogger(__name__)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# hashing the password
def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


# verifying the password
def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify password with backward compatibility for plain text passwords.
    Returns True if password matches, False otherwise.
    """
    if is_password_hashed(hashed_password):
        try:
            return pwd_context.verify(plain_password, hashed_password)
        except (TypeError, ValueError):
            return False

    return hmac.compare_digest(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))

def is_password_hashed(password: str) -> bool:
    """Check if a password is already properly hashed with bcrypt"""
    return password.startswith('$2b$') or password.startswith('$2a$') or password.startswith('$2y$')

async def upgrade_password_if_needed(db, user, plain_password: str) -> bool:
    """
    Upgrade plain text password to bcrypt hash if needed.
    Returns True if password was upgraded, False if already hashed.
    """
    if not is_password_hashed(user.hashed_password):
        # Password is plain text, upgrade it
        user.hashed_password = get_password_hash(plain_password)
        db.add(user)
        await db.commit()
        logger.info("Upgraded legacy password for user_id=%s", user.id)
        return True
    return False

# JWT token creation and verification
SECRET_KEY = settings.SECRET_KEY
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = settings.ACCESS_TOKEN_EXPIRE_MINUTES


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access"
    })

    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    """Create JWT refresh token with longer expiration"""
    to_encode = data.copy()
    
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "refresh"
    })
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt

def decode_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        logger.info("Rejected invalid or expired authentication token")
        return None

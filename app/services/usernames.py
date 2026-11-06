"""Readable login usernames for guardians: firstname_lastname, transliterated from Arabic."""
import re
import unicodedata

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User

# Simple, predictable Arabic -> Latin mapping (not scholarly; meant to be easy to type).
ARABIC_TO_LATIN = {
    "ا": "a", "أ": "a", "إ": "i", "آ": "a", "ء": "", "ؤ": "o", "ئ": "i", "ب": "b", "ت": "t", "ث": "th",
    "ج": "dj", "ح": "h", "خ": "kh", "د": "d", "ذ": "dh", "ر": "r", "ز": "z", "س": "s", "ش": "ch",
    "ص": "s", "ض": "d", "ط": "t", "ظ": "dh", "ع": "a", "غ": "gh", "ف": "f", "ق": "k", "ك": "k",
    "ل": "l", "م": "m", "ن": "n", "ه": "h", "ة": "a", "و": "ou", "ي": "i", "ى": "a",
}
MAX_LENGTH = 40


def slug(text: str) -> str:
    """'محمد الأمين' -> 'mhmd_alamin'-like ASCII token; Latin names keep their letters."""
    out = []
    for char in (text or "").strip().lower():
        if char in ARABIC_TO_LATIN:
            out.append(ARABIC_TO_LATIN[char])
        elif char.isspace() or char in "-_.'":
            out.append("_")
        else:
            # strip accents: é -> e
            out.append(unicodedata.normalize("NFKD", char).encode("ascii", "ignore").decode())
    token = re.sub(r"[^a-z0-9_]", "", "".join(out))
    return re.sub(r"_+", "_", token).strip("_")


def base_username(first_name: str, last_name: str) -> str:
    parts = [p for p in (slug(first_name), slug(last_name)) if p]
    return ("_".join(parts) or "parent")[:MAX_LENGTH]


async def suggest_username(db: AsyncSession, first_name: str, last_name: str) -> str:
    """firstname_lastname, or firstname_lastname2, 3... when already taken (case-insensitive)."""
    base = base_username(first_name, last_name)
    candidate, n = base, 1
    while await db.scalar(select(User.id).where(func.lower(User.email) == candidate).limit(1)) is not None:
        n += 1
        candidate = f"{base[: MAX_LENGTH - len(str(n))]}{n}"
    return candidate

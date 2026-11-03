"""Private draft notes ("brouillon") for teachers. Each teacher only ever sees their own notes."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import require_teacher
from app.db.session import get_db
from app.models.teacher_note import TeacherNote

notesRouter = APIRouter()

MAX_NOTES_PER_TEACHER = 500


class NoteCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str = Field(default="", max_length=200)
    content: str = Field(default="", max_length=20000)
    pinned: bool = False


class NoteUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str | None = Field(default=None, max_length=200)
    content: str | None = Field(default=None, max_length=20000)
    pinned: bool | None = None


class NoteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    content: str
    pinned: bool
    created_at: datetime
    updated_at: datetime


async def _own_note(db: AsyncSession, note_id: int, user_id: int) -> TeacherNote:
    note = await db.scalar(select(TeacherNote).where(TeacherNote.id == note_id, TeacherNote.user_id == user_id))
    if note is None:
        raise HTTPException(status_code=404, detail="Note not found")
    return note


@notesRouter.get("/", response_model=list[NoteResponse])
async def list_notes(db: AsyncSession = Depends(get_db), teacher=Depends(require_teacher)):
    result = await db.execute(
        select(TeacherNote)
        .where(TeacherNote.user_id == teacher.id)
        .order_by(TeacherNote.pinned.desc(), TeacherNote.updated_at.desc())
    )
    return result.scalars().all()


@notesRouter.post("/", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def create_note(data: NoteCreate, db: AsyncSession = Depends(get_db), teacher=Depends(require_teacher)):
    existing = await db.execute(select(TeacherNote.id).where(TeacherNote.user_id == teacher.id).limit(MAX_NOTES_PER_TEACHER))
    if len(existing.all()) >= MAX_NOTES_PER_TEACHER:
        raise HTTPException(status_code=409, detail="Note limit reached")
    note = TeacherNote(user_id=teacher.id, title=data.title.strip(), content=data.content, pinned=data.pinned)
    db.add(note)
    await db.commit()
    await db.refresh(note)
    return note


@notesRouter.patch("/{note_id}", response_model=NoteResponse)
async def update_note(note_id: int, data: NoteUpdate, db: AsyncSession = Depends(get_db), teacher=Depends(require_teacher)):
    note = await _own_note(db, note_id, teacher.id)
    changes = data.model_dump(exclude_unset=True)
    if "title" in changes and changes["title"] is not None:
        note.title = changes["title"].strip()
    if "content" in changes and changes["content"] is not None:
        note.content = changes["content"]
    if "pinned" in changes and changes["pinned"] is not None:
        note.pinned = changes["pinned"]
    await db.commit()
    await db.refresh(note)
    return note


@notesRouter.delete("/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_note(note_id: int, db: AsyncSession = Depends(get_db), teacher=Depends(require_teacher)):
    note = await _own_note(db, note_id, teacher.id)
    await db.delete(note)
    await db.commit()

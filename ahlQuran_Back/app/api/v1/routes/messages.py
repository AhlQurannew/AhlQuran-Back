from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.db.session import get_db
from app.models.user import User
from app.models.message import Message
from app.schemas.message import MessageCreate, MessageResponse, MessageList
from app.core.dependencies import get_current_user
import logging

logger = logging.getLogger(__name__)

messageRouter = APIRouter()


async def get_president_id_for_user(current_user: User, db: AsyncSession) -> int:
    """
    Get the president_id for any user (president, teacher, or supervisor).
    Raises HTTPException if unable to determine organization.
    """
    president_id = None
    
    if current_user.role.value == "PRESIDENT":
        from app.models.president import President
        result = await db.execute(
            select(President).where(President.user_id == current_user.id)
        )
        president = result.scalar_one_or_none()
        if president:
            president_id = president.id
    elif current_user.role.value == "TEACHER":
        from app.models.teacher import Teacher
        result = await db.execute(
            select(Teacher).where(Teacher.user_id == current_user.id)
        )
        teacher = result.scalar_one_or_none()
        if teacher:
            president_id = teacher.president_id
    elif current_user.role.value == "SUPERVISOR":
        from app.models.supervisor import Supervisor
        result = await db.execute(
            select(Supervisor).where(Supervisor.user_id == current_user.id)
        )
        supervisor = result.scalar_one_or_none()
        if supervisor:
            president_id = supervisor.president_id
    
    if not president_id:
        raise HTTPException(status_code=403, detail="Unable to determine organization")
    
    return president_id


@messageRouter.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def create_message(
    message_data: MessageCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new message. Any authenticated user (teacher/supervisor/president) can send messages.
    The sender's name is automatically extracted from the current user.
    """
    
    # Get president ID based on user role
    president_id = await get_president_id_for_user(current_user, db)
    
    # Get sender name from current user
    sender_name = f"{current_user.firstname} {current_user.lastname}"
    
    # Create new message with president_id
    new_message = Message(
        sender_id=current_user.id,
        sender_name=sender_name,
        sender_role=message_data.sender_role,
        message=message_data.message,
        president_id=president_id
    )
    
    db.add(new_message)
    await db.commit()
    await db.refresh(new_message)
    
    logger.info(f"Message created by {sender_name} ({message_data.sender_role})")
    
    return new_message


@messageRouter.get("/", response_model=MessageList)
async def get_messages(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all messages ordered by creation time (newest first).
    Any authenticated user can view messages.
    """
    
    # Get president ID based on user role
    president_id = await get_president_id_for_user(current_user, db)
    
    # Get messages ordered by created_at descending (newest first), filtered by president_id
    result = await db.execute(
        select(Message)
        .where(Message.president_id == president_id)
        .order_by(Message.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    messages = result.scalars().all()
    
    # Get total count with same filter
    count_result = await db.execute(
        select(func.count(Message.id)).where(Message.president_id == president_id)
    )
    total = count_result.scalar() or 0
    
    return MessageList(messages=list(messages), total=total)


@messageRouter.get("/recent", response_model=MessageList)
async def get_recent_messages(
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get recent messages (default last 50).
    Optimized for polling - returns newest messages first.
    """
    
    # Get president ID based on user role
    president_id = await get_president_id_for_user(current_user, db)
    
    # Get recent messages ordered by created_at descending, filtered by president_id
    result = await db.execute(
        select(Message)
        .where(Message.president_id == president_id)
        .order_by(Message.created_at.desc())
        .limit(limit)
    )
    messages = result.scalars().all()
    
    # Get total count with same filter
    count_result = await db.execute(
        select(func.count(Message.id)).where(Message.president_id == president_id)
    )
    total = count_result.scalar() or 0
    
    return MessageList(messages=list(messages), total=total)


@messageRouter.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    message_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a message. Only the sender can delete their own message.
    """
    
    # Get the message
    result = await db.execute(
        select(Message).where(Message.id == message_id)
    )
    message = result.scalar_one_or_none()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Message with ID {message_id} not found"
        )
    
    # Check if current user is the sender
    if message.sender_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own messages"
        )
    
    await db.delete(message)
    await db.commit()
    
    logger.info(f"Message {message_id} deleted by user {current_user.id}")
    
    return None

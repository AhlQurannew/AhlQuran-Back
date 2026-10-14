from fastapi import APIRouter, HTTPException, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.db.session import get_db
from app.models.user import User
from app.models.message import Message, SenderRole
from app.schemas.message import MessageCreate, MessageResponse, MessageList
from app.core.dependencies import get_current_user
from app.core.multi_tenancy import get_president_id_for_user as resolve_president_id
from app.api.v1.routes.ws_messages import broadcast_to_group
import logging

logger = logging.getLogger(__name__)

messageRouter = APIRouter()


async def get_president_id_for_user(current_user: User, db: AsyncSession) -> int:
    return await resolve_president_id(current_user, db)


def get_sender_role(user: User) -> SenderRole:
    role = user.role.value if hasattr(user.role, "value") else str(user.role)
    if role == "CHIEF_SUPERVISOR":
        role = "SUPERVISOR"
    try:
        return SenderRole(role.lower())
    except ValueError as exc:
        raise HTTPException(status_code=403, detail="This account cannot send messages") from exc


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
        sender_role=get_sender_role(current_user),
        message=message_data.message,
        president_id=president_id
    )
    
    db.add(new_message)
    await db.commit()
    await db.refresh(new_message)
    
    logger.info("Message created by user_id=%s", current_user.id)

    # Broadcast to active WebSocket clients
    try:
        await broadcast_to_group(president_id, {
            "type": "message",
            "id": new_message.id,
            "sender_id": new_message.sender_id,
            "sender_name": new_message.sender_name,
            "sender_role": new_message.sender_role.value if hasattr(new_message.sender_role, "value") else str(new_message.sender_role),
            "message": new_message.message,
            "created_at": new_message.created_at.isoformat(),
        })
    except Exception as e:
        logger.warning(f"Failed to broadcast REST created message over WS: {e}")
    
    return new_message


@messageRouter.get("/", response_model=MessageList)
async def get_messages(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
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
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get recent messages (default last 50).
    Optimized for polling / initial load - returns newest messages first.
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
    
    president_id = await get_president_id_for_user(current_user, db)
    result = await db.execute(
        select(Message).where(
            Message.id == message_id,
            Message.president_id == president_id,
        )
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
    
    if president_id:
        try:
            await broadcast_to_group(president_id, {
                "type": "delete",
                "id": message_id
            })
        except Exception as e:
            logger.warning(f"Failed to broadcast message deletion over WS: {e}")
    
    return None

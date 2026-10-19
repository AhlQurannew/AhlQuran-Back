from typing import Optional
from fastapi import APIRouter, HTTPException, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.message import Message, SenderRole
from app.models.president import President
from app.schemas.message import MessageCreate, MessageResponse, MessageList
from app.core.dependencies import get_current_user
from app.api.v1.routes.ws_messages import broadcast_to_group
import logging

logger = logging.getLogger(__name__)

messageRouter = APIRouter()


async def get_president_id_for_user(current_user, db: AsyncSession, school_id: Optional[int] = None) -> int:
    """
    Get the president_id for any user (president, supervisor, teacher, or admin).
    Raises HTTPException if unable to determine organization.
    """
    from app.models.admin import Admin
    
    # 1. Admin users
    if isinstance(current_user, Admin) or getattr(current_user, "role", None) in ("admin", "ADMIN") or hasattr(current_user, "is_admin"):
        if school_id:
            result = await db.execute(select(President).where(President.id == school_id))
            pres = result.scalar_one_or_none()
            if pres:
                return pres.id
        result = await db.execute(select(President).limit(1))
        pres = result.scalar_one_or_none()
        if pres:
            return pres.id
        raise HTTPException(status_code=403, detail="No school organization found")

    role = current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role)
    president_id = None
    
    if role == "PRESIDENT":
        result = await db.execute(
            select(President).where(President.user_id == current_user.id)
        )
        president = result.scalar_one_or_none()
        if president:
            president_id = president.id
    elif role == "TEACHER":
        from app.models.teacher import Teacher
        result = await db.execute(
            select(Teacher).where(Teacher.user_id == current_user.id)
        )
        teacher = result.scalar_one_or_none()
        if teacher:
            president_id = teacher.president_id
    elif role == "SUPERVISOR":
        from app.models.supervisor import Supervisor
        result = await db.execute(
            select(Supervisor).where(Supervisor.user_id == current_user.id)
        )
        supervisor = result.scalar_one_or_none()
        if supervisor and supervisor.president_id:
            president_id = supervisor.president_id
        else:
            result = await db.execute(select(President).limit(1))
            pres = result.scalar_one_or_none()
            if pres:
                president_id = pres.id
    elif role in ("CHIEF_SUPERVISOR", "chief_supervisor"):
        from app.models.chief_supervisor import ChiefSupervisor
        result = await db.execute(
            select(ChiefSupervisor).where(ChiefSupervisor.user_id == current_user.id)
        )
        chief_supervisor = result.scalar_one_or_none()
        if chief_supervisor and chief_supervisor.president_id:
            president_id = chief_supervisor.president_id
        else:
            from app.models.supervisor import Supervisor
            result = await db.execute(
                select(Supervisor).where(Supervisor.user_id == current_user.id)
            )
            sup = result.scalar_one_or_none()
            if sup and sup.president_id:
                president_id = sup.president_id
            else:
                result = await db.execute(select(President).limit(1))
                pres = result.scalar_one_or_none()
                if pres:
                    president_id = pres.id
    
    if not president_id:
        raise HTTPException(status_code=403, detail="Unable to determine organization")
    
    return president_id


@messageRouter.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def create_message(
    message_data: MessageCreate,
    school_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Create a new message. Any authenticated user (teacher/supervisor/president/admin) can send messages.
    """
    president_id = await get_president_id_for_user(current_user, db, school_id=school_id)
    
    from app.models.admin import Admin
    is_admin_user = isinstance(current_user, Admin) or getattr(current_user, "role", None) in ("admin", "ADMIN") or hasattr(current_user, "is_admin")
    
    if is_admin_user:
        result = await db.execute(select(President).where(President.id == president_id))
        pres = result.scalar_one_or_none()
        sender_id = pres.user_id if pres else current_user.id
        sender_name = "الرئيس"
        sender_role = SenderRole.PRESIDENT
    else:
        sender_id = current_user.id
        sender_name = f"{getattr(current_user, 'firstname', '')} {getattr(current_user, 'lastname', '')}".strip() or "مستخدم"
        raw_role = str(message_data.sender_role).lower()
        if raw_role in ("supervisor", "chief_supervisor"):
            sender_role = SenderRole.SUPERVISOR
        elif raw_role in ("president", "admin"):
            sender_role = SenderRole.PRESIDENT
        else:
            sender_role = SenderRole.TEACHER
    
    # Create new message with president_id
    new_message = Message(
        sender_id=sender_id,
        sender_name=sender_name,
        sender_role=sender_role,
        message=message_data.message,
        president_id=president_id
    )
    
    db.add(new_message)
    await db.commit()
    await db.refresh(new_message)
    
    logger.info(f"Message created by {sender_name} ({sender_role})")

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
    skip: int = 0,
    limit: int = 100,
    school_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get all messages ordered by creation time (newest first).
    Any authenticated user can view messages.
    """
    president_id = await get_president_id_for_user(current_user, db, school_id=school_id)
    
    result = await db.execute(
        select(Message)
        .where(Message.president_id == president_id)
        .order_by(Message.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    messages = result.scalars().all()
    
    count_result = await db.execute(
        select(func.count(Message.id)).where(Message.president_id == president_id)
    )
    total = count_result.scalar() or 0
    
    return MessageList(messages=list(messages), total=total)


@messageRouter.get("/recent", response_model=MessageList)
async def get_recent_messages(
    limit: int = 50,
    school_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get recent messages (default last 50).
    Optimized for polling / initial load - returns newest messages first.
    """
    president_id = await get_president_id_for_user(current_user, db, school_id=school_id)
    
    result = await db.execute(
        select(Message)
        .where(Message.president_id == president_id)
        .order_by(Message.created_at.desc())
        .limit(limit)
    )
    messages = result.scalars().all()
    
    count_result = await db.execute(
        select(func.count(Message.id)).where(Message.president_id == president_id)
    )
    total = count_result.scalar() or 0
    
    return MessageList(messages=list(messages), total=total)


@messageRouter.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    message_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Delete a message. Sender or president/admin can delete messages.
    """
    result = await db.execute(
        select(Message).where(Message.id == message_id)
    )
    message = result.scalar_one_or_none()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Message with ID {message_id} not found"
        )
    
    from app.models.admin import Admin
    is_admin = isinstance(current_user, Admin) or getattr(current_user, "role", None) in ("admin", "ADMIN") or hasattr(current_user, "is_admin")
    is_pres = getattr(current_user, "role", None) == UserRoleEnum.PRESIDENT
    
    if message.sender_id != current_user.id and not is_admin and not is_pres:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own messages"
        )
    
    president_id = message.president_id
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

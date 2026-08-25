"""
Fix existing messages that might have NULL sender_id values.
This script will delete messages with NULL sender_id since we can't reliably determine who sent them.
"""
import asyncio
from sqlalchemy import select, delete
from app.db.session import AsyncSessionLocal
from app.models.message import Message


async def fix_messages():
    async with AsyncSessionLocal() as db:
        # Check for messages with NULL sender_id
        result = await db.execute(
            select(Message).where(Message.sender_id == None)
        )
        null_messages = result.scalars().all()
        
        if null_messages:
            print(f"Found {len(null_messages)} messages with NULL sender_id")
            print("Deleting these messages...")
            
            await db.execute(
                delete(Message).where(Message.sender_id == None)
            )
            await db.commit()
            print("Done! Old messages deleted.")
        else:
            print("No messages with NULL sender_id found. All good!")
        
        # Show current message count
        result = await db.execute(select(Message))
        all_messages = result.scalars().all()
        print(f"\nTotal messages in database: {len(all_messages)}")
        
        if all_messages:
            print("\nSample messages:")
            for msg in all_messages[:5]:
                print(f"  - ID: {msg.id}, Sender ID: {msg.sender_id}, Name: {msg.sender_name}")


if __name__ == "__main__":
    asyncio.run(fix_messages())

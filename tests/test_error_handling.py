"""
Test error handling for guardian student data access endpoints.
"""
import pytest
from unittest.mock import AsyncMock, patch
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.v1.routes.guardian import (
    get_achievements_for_student,
    get_attendance_for_student,
    verify_guardian_student_access
)


@pytest.mark.asyncio
async def test_get_achievements_handles_database_error():
    """Test that get_achievements_for_student handles database errors gracefully."""
    # Create a mock database session that raises an exception
    mock_db = AsyncMock(spec=AsyncSession)
    mock_db.execute.side_effect = Exception("Database connection failed")
    
    # Verify that the function raises HTTPException with 500 status
    with pytest.raises(HTTPException) as exc_info:
        await get_achievements_for_student(
            db=mock_db,
            student_id=1,
            president_id=1,
            start_date=None,
            end_date=None,
            skip=0,
            limit=50
        )
    
    assert exc_info.value.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert "internal error" in exc_info.value.detail.lower()


@pytest.mark.asyncio
async def test_get_attendance_handles_database_error():
    """Test that get_attendance_for_student handles database errors gracefully."""
    # Create a mock database session that raises an exception
    mock_db = AsyncMock(spec=AsyncSession)
    mock_db.execute.side_effect = Exception("Database connection failed")
    
    # Verify that the function raises HTTPException with 500 status
    with pytest.raises(HTTPException) as exc_info:
        await get_attendance_for_student(
            db=mock_db,
            student_id=1,
            president_id=1,
            start_date=None,
            end_date=None,
            skip=0,
            limit=50
        )
    
    assert exc_info.value.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert "internal error" in exc_info.value.detail.lower()


@pytest.mark.asyncio
async def test_error_messages_are_descriptive():
    """Test that error messages are descriptive and user-friendly."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_db.execute.side_effect = Exception("Database connection failed")
    
    # Test achievements error message
    with pytest.raises(HTTPException) as exc_info:
        await get_achievements_for_student(
            db=mock_db,
            student_id=1,
            president_id=1
        )
    
    assert "achievements" in exc_info.value.detail.lower()
    assert "try again later" in exc_info.value.detail.lower()
    
    # Test attendance error message
    with pytest.raises(HTTPException) as exc_info:
        await get_attendance_for_student(
            db=mock_db,
            student_id=1,
            president_id=1
        )
    
    assert "attendance" in exc_info.value.detail.lower()
    assert "try again later" in exc_info.value.detail.lower()

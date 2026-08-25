"""
Unit tests for guardian attendance endpoint.
Tests the GET /api/v1/guardian/students/{student_id}/attendance endpoint.
"""
import pytest
from app.api.v1.routes.guardian import guardianRouter
from fastapi.testclient import TestClient
from fastapi import FastAPI


def test_attendance_endpoint_exists():
    """
    Test that the attendance endpoint is registered and has correct structure.
    Validates: Task 6.1 - endpoint definition
    """
    # Create a test app with the guardian router
    app = FastAPI()
    app.include_router(guardianRouter, prefix="/api/v1/guardian")
    
    # Get all routes
    routes = [route for route in app.routes]
    
    # Find the attendance endpoint
    attendance_route = None
    for route in routes:
        if hasattr(route, 'path') and '/students/{student_id}/attendance' in route.path:
            attendance_route = route
            break
    
    # Verify endpoint exists
    assert attendance_route is not None, "Attendance endpoint not found"
    
    # Verify it's a GET endpoint
    assert 'GET' in attendance_route.methods
    
    # Verify path parameters
    assert 'student_id' in attendance_route.path
    
    print("✓ Attendance endpoint exists with correct structure")


def test_attendance_endpoint_has_correct_parameters():
    """
    Test that the attendance endpoint has the correct query parameters.
    Validates: Task 6.1 - query parameters definition
    """
    from app.api.v1.routes.guardian import get_student_attendance
    import inspect
    
    # Get function signature
    sig = inspect.signature(get_student_attendance)
    params = sig.parameters
    
    # Verify required parameters exist
    assert 'student_id' in params, "student_id parameter missing"
    assert 'start_date' in params, "start_date parameter missing"
    assert 'end_date' in params, "end_date parameter missing"
    assert 'page' in params, "page parameter missing"
    assert 'page_size' in params, "page_size parameter missing"
    assert 'db' in params, "db parameter missing"
    assert 'current_user' in params, "current_user parameter missing"
    
    print("✓ Attendance endpoint has correct parameters")


def test_attendance_endpoint_response_model():
    """
    Test that the attendance endpoint has the correct response model.
    Validates: Task 6.1 - response model definition
    """
    from app.api.v1.routes.guardian import get_student_attendance
    import inspect
    
    # Get function signature
    sig = inspect.signature(get_student_attendance)
    
    # Verify return type annotation
    return_annotation = sig.return_annotation
    assert return_annotation is not inspect.Signature.empty, "Return type annotation missing"
    assert 'PaginatedAttendanceResponse' in str(return_annotation), "Incorrect return type"
    
    print("✓ Attendance endpoint has correct response model")

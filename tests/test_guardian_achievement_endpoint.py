"""
Unit tests for guardian achievement endpoint.
Tests the GET /api/v1/guardian/students/{student_id}/achievements endpoint.
"""
import pytest
from app.api.v1.routes.guardian import guardianRouter
from fastapi.testclient import TestClient
from fastapi import FastAPI


def test_achievement_endpoint_exists():
    """
    Test that the achievement endpoint is registered and has correct structure.
    Validates: Task 5.1 - endpoint definition
    """
    # Create a test app with the guardian router
    app = FastAPI()
    app.include_router(guardianRouter, prefix="/api/v1/guardian")
    
    # Get all routes
    routes = [route for route in app.routes]
    
    # Find the achievement endpoint
    achievement_route = None
    for route in routes:
        if hasattr(route, 'path') and '/students/{student_id}/achievements' in route.path:
            achievement_route = route
            break
    
    # Verify endpoint exists
    assert achievement_route is not None, "Achievement endpoint not found"
    
    # Verify it's a GET endpoint
    assert 'GET' in achievement_route.methods
    
    # Verify path parameters
    assert 'student_id' in achievement_route.path
    
    print("✓ Achievement endpoint exists with correct structure")


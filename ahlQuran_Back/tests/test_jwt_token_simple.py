"""
Simple unit test for JWT token structure (Property 4)
Feature: guardian-authentication-system
"""
import pytest
from app.core.security import create_access_token, decode_token
from app.core.config import settings
from datetime import timedelta, datetime, timezone


def test_jwt_token_structure():
    """
    Property 4: JWT Token Structure
    
    For any successfully generated JWT token for a guardian, decoding the token should reveal
    the guardian's email, user_id, role (GUARDIAN), and token type, and the token expiration
    should match the configured ACCESS_TOKEN_EXPIRE_MINUTES setting.
    
    Validates: Requirements 1.8, 7.4
    """
    # Test data
    test_cases = [
        {"email": "guardian1@test.com", "user_id": 1},
        {"email": "guardian2@example.org", "user_id": 100},
        {"email": "test@domain.co.uk", "user_id": 999},
    ]
    
    for test_data in test_cases:
        # Create a JWT token
        access_token = create_access_token(
            data={
                "email": test_data["email"],
                "user_id": test_data["user_id"],
                "role": "GUARDIAN",
                "type": "user"  # This will be overwritten to "access"
            },
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        
        # Decode the JWT token
        payload = decode_token(access_token)
        
        # Assertions
        assert payload is not None, "Token should be decodable"
        assert payload["email"] == test_data["email"], \
            f"Token should contain email {test_data['email']}, got {payload.get('email')}"
        assert payload["user_id"] == test_data["user_id"], \
            f"Token should contain user_id {test_data['user_id']}, got {payload.get('user_id')}"
        assert payload["role"] == "GUARDIAN", \
            f"Token should contain GUARDIAN role, got {payload.get('role')}"
        assert payload["type"] == "access", \
            f"Token should have type 'access', got {payload.get('type')}"
        
        # Verify token has expiration and issued at time
        assert "exp" in payload, "Token should have expiration"
        assert "iat" in payload, "Token should have issued at time"
        
        # Verify token expiration is set correctly
        exp_time = datetime.fromtimestamp(payload["exp"], tz=timezone.utc)
        iat_time = datetime.fromtimestamp(payload["iat"], tz=timezone.utc)
        token_lifetime_minutes = (exp_time - iat_time).total_seconds() / 60
        
        # Token lifetime should be close to ACCESS_TOKEN_EXPIRE_MINUTES (allow 1 minute tolerance)
        expected_lifetime = settings.ACCESS_TOKEN_EXPIRE_MINUTES
        assert abs(token_lifetime_minutes - expected_lifetime) <= 1, \
            f"Token lifetime should be approximately {expected_lifetime} minutes, got {token_lifetime_minutes}"

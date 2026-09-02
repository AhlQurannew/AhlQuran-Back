"""
Simple test to verify the guardian endpoint is properly registered and accessible.
This is a manual verification script, not part of the test suite.
"""
import asyncio
from httpx import AsyncClient
from app.main import app

async def test_endpoint_exists():
    """Test that the /api/v1/guardians/my-children endpoint exists"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Try to access the endpoint without authentication (should get 401)
        response = await client.get("/api/v1/guardians/my-children")
        
        # We expect 401 (not authenticated) or 403 (not authorized)
        # NOT 404 (endpoint doesn't exist)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 404:
            print("❌ FAIL: Endpoint not found (404)")
            return False
        elif response.status_code in [401, 403]:
            print("✅ PASS: Endpoint exists and requires authentication")
            return True
        else:
            print(f"⚠️  UNEXPECTED: Got status code {response.status_code}")
            return True

if __name__ == "__main__":
    result = asyncio.run(test_endpoint_exists())
    exit(0 if result else 1)

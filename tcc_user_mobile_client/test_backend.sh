#!/bin/bash

# Script to test backend connectivity and login endpoint

echo "🔧 Backend Connection Test"
echo "=========================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check if backend is reachable
echo "Test 1: Checking if backend is reachable..."
if curl -s http://localhost:3000/v1 > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Backend is reachable at http://localhost:3000/v1"
else
    echo -e "${RED}✗${NC} Backend is NOT reachable"
    echo "  → Make sure backend is running: npm start"
    exit 1
fi
echo ""

# Test 2: Check login endpoint with test credentials
echo "Test 2: Testing login endpoint..."
echo "Please enter test credentials:"
read -p "Email: " email
read -sp "Password: " password
echo ""
echo ""

echo "Sending login request..."
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$email\",\"password\":\"$password\"}")

http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
body=$(echo "$response" | grep -v "HTTP_CODE:")

echo "Response Status: $http_code"
echo "Response Body:"
echo "$body" | jq '.' 2>/dev/null || echo "$body"
echo ""

# Interpret the response
case $http_code in
    200)
        echo -e "${GREEN}✓${NC} Login successful!"
        echo "  → These credentials work. Use them in the app."
        ;;
    401)
        echo -e "${RED}✗${NC} Login failed: Unauthorized (401)"
        echo "  → Invalid credentials or account doesn't exist"
        echo "  → Check backend logs for more details"
        echo "  → Verify account exists in database"
        ;;
    422)
        echo -e "${YELLOW}⚠${NC} Login failed: Validation Error (422)"
        echo "  → Email or password format is invalid"
        echo "  → Check the validation errors above"
        ;;
    404)
        echo -e "${RED}✗${NC} Login failed: Not Found (404)"
        echo "  → Login endpoint doesn't exist or wrong URL"
        echo "  → Check backend routes"
        ;;
    500)
        echo -e "${RED}✗${NC} Login failed: Server Error (500)"
        echo "  → Backend has an internal error"
        echo "  → Check backend logs and database connection"
        ;;
    000)
        echo -e "${RED}✗${NC} No response from backend"
        echo "  → Backend may have crashed or is not running"
        ;;
    *)
        echo -e "${YELLOW}⚠${NC} Unexpected response code: $http_code"
        echo "  → Check backend logs for details"
        ;;
esac
echo ""

# Test 3: From emulator perspective (Android)
echo "Test 3: Testing from Android emulator perspective..."
echo "(This simulates the request from the emulator)"
echo ""

response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://10.0.2.2:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$email\",\"password\":\"$password\"}" 2>&1)

if echo "$response" | grep -q "Could not resolve host\|Failed to connect"; then
    echo -e "${YELLOW}⚠${NC} Cannot test from emulator perspective from host machine"
    echo "  → This is normal when testing from your computer"
    echo "  → The emulator itself can reach 10.0.2.2"
else
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✓${NC} Backend is accessible from emulator IP"
    else
        echo -e "${YELLOW}⚠${NC} Got response code: $http_code"
    fi
fi
echo ""

# Summary
echo "=========================="
echo "Summary:"
echo "=========================="
echo ""
echo "Backend Status:"
echo "  Base URL: http://localhost:3000/v1"
echo "  Emulator URL: http://10.0.2.2:3000/v1"
echo "  Status: $([ $http_code == "200" ] && echo -e "${GREEN}Working${NC}" || echo -e "${RED}Issues Detected${NC}")"
echo ""
echo "Next Steps:"
if [ "$http_code" == "200" ]; then
    echo "  1. Use these credentials in the mobile app"
    echo "  2. Run: flutter run"
    echo "  3. Login with: $email"
else
    echo "  1. Fix the backend issue (see errors above)"
    echo "  2. Verify test account exists in database"
    echo "  3. Check backend logs"
    echo "  4. Try different credentials"
fi
echo ""

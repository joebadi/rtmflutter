#!/bin/bash

# Flutter Verification Script
# This script runs comprehensive checks before pushing code to Git

set -e  # Exit on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track overall status
CHECKS_PASSED=0
CHECKS_FAILED=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Flutter Verification System${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗${NC} $2"
        ((CHECKS_FAILED++))
    fi
}

# 1. Check dependencies
echo -e "${YELLOW}[1/5]${NC} Checking dependencies..."
if /opt/flutter/bin/flutter pub get > /dev/null 2>&1; then
    print_status 0 "Dependencies are up to date"
else
    print_status 1 "Failed to get dependencies"
    exit 1
fi
echo ""

# 2. Run Flutter analyze
echo -e "${YELLOW}[2/5]${NC} Running code analysis..."
if /opt/flutter/bin/flutter analyze --no-fatal-infos; then
    print_status 0 "No critical analysis issues found"
else
    print_status 1 "Analysis found critical issues"
    exit 1
fi
echo ""

# 3. Check code formatting
echo -e "${YELLOW}[3/5]${NC} Checking code formatting..."
if /opt/flutter/bin/dart format --set-exit-if-changed lib/ test/ > /dev/null 2>&1; then
    print_status 0 "Code is properly formatted"
else
    print_status 1 "Code formatting issues found (run ./fix-formatting.sh to fix)"
    exit 1
fi
echo ""

# 4. Run tests
echo -e "${YELLOW}[4/5]${NC} Running tests..."
if /opt/flutter/bin/flutter test; then
    print_status 0 "All tests passed"
else
    print_status 1 "Some tests failed"
    exit 1
fi
echo ""

# 5. Build verification (optional - can be commented out if too slow)
echo -e "${YELLOW}[5/5]${NC} Verifying build (debug mode)..."
if /opt/flutter/bin/flutter build apk --debug > /dev/null 2>&1; then
    print_status 0 "Build successful"
else
    print_status 1 "Build failed"
    exit 1
fi
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ All verification checks passed!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Your code is ready to push to Git! 🚀"
echo ""

exit 0

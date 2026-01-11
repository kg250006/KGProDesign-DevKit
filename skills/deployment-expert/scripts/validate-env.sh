#!/bin/bash
# Validates environment variables against deployment profile requirements
# Usage: validate-env.sh [env-file] [profile-file]

set -e

ENV_FILE=${1:-.env.production}
PROFILE=${2:-.deployment-profile.json}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Validating environment variables..."
echo "  Env file: $ENV_FILE"
echo "  Profile: $PROFILE"
echo ""

# Check files exist
if [ ! -f "$PROFILE" ]; then
    echo -e "${RED}Error: Profile not found: $PROFILE${NC}"
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Warning: Env file not found: $ENV_FILE${NC}"
    echo "Creating from .env.example if available..."
    if [ -f ".env.example" ]; then
        cp .env.example "$ENV_FILE"
        echo "Created $ENV_FILE from .env.example"
    else
        echo -e "${RED}Error: No env file and no .env.example to copy${NC}"
        exit 1
    fi
fi

# Get required variables from profile
REQUIRED=$(jq -r '.envVars.required[]? // empty' "$PROFILE" 2>/dev/null)
OPTIONAL=$(jq -r '.envVars.optional[]? // empty' "$PROFILE" 2>/dev/null)

MISSING=()
PRESENT=()
OPTIONAL_MISSING=()

# Check required variables
for var in $REQUIRED; do
    if grep -q "^$var=" "$ENV_FILE" 2>/dev/null; then
        value=$(grep "^$var=" "$ENV_FILE" | cut -d= -f2-)
        if [ -n "$value" ] && [ "$value" != '""' ] && [ "$value" != "''" ]; then
            PRESENT+=("$var")
        else
            MISSING+=("$var (empty value)")
        fi
    else
        MISSING+=("$var")
    fi
done

# Check optional variables
for var in $OPTIONAL; do
    if ! grep -q "^$var=" "$ENV_FILE" 2>/dev/null; then
        OPTIONAL_MISSING+=("$var")
    fi
done

# Report results
echo "Required variables:"
for var in "${PRESENT[@]}"; do
    echo -e "  ${GREEN}✓${NC} $var"
done
for var in "${MISSING[@]}"; do
    echo -e "  ${RED}✗${NC} $var"
done

if [ ${#OPTIONAL_MISSING[@]} -gt 0 ]; then
    echo ""
    echo "Optional variables (not set):"
    for var in "${OPTIONAL_MISSING[@]}"; do
        echo -e "  ${YELLOW}○${NC} $var"
    done
fi

echo ""

# Exit with error if required vars missing
if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}Validation failed: ${#MISSING[@]} required variable(s) missing${NC}"
    exit 1
else
    echo -e "${GREEN}Validation passed: All required variables are set${NC}"
    exit 0
fi

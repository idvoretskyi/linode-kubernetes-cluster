#!/bin/bash
# Security check script for open source release
# Run this before making the repository public

set -e

echo "🔒 Security Check for Open Source Release"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ISSUES_FOUND=0

# Function to report issues
report_issue() {
    echo -e "${RED}❌ ISSUE:${NC} $1"
    ((ISSUES_FOUND++))
}

report_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

report_ok() {
    echo -e "${GREEN}✅ OK:${NC} $1"
}

echo "1. Checking for hardcoded sensitive data..."

# Check for potential API tokens
if grep -r "token.*=" . --exclude-dir=.git --exclude="*.sh" | grep -v "LINODE_TOKEN" | grep -v "your-token" | grep -v "your-linode-api-token" | grep -v "module\..*\.cluster_token"; then
    report_issue "Found potential hardcoded tokens"
else
    report_ok "No hardcoded tokens found"
fi

# Check for IP addresses (allow documentation examples)
if grep -r "192\.168\." . --exclude-dir=.git --exclude="*.sh" | grep -v "192.168.1.0/24" | grep -v "example"; then
    report_warning "Found real IP addresses - verify they are examples only"
else
    report_ok "No real IP addresses found"
fi

# Check for email addresses
if grep -r "@" . --exclude-dir=.git --exclude="*.sh" | grep -v "example.com" | grep -v "@.type" | grep -v "managed-by" | grep -v "CNCF"; then
    report_warning "Found email addresses - verify they are examples only"
else
    report_ok "No real email addresses found"
fi

echo ""
echo "2. Checking firewall configurations..."

# Check for overly permissive firewall rules
if grep -r "0\.0\.0\.0/0" infrastructure/ | grep -v "# CHANGE THIS" | grep -v "# restrict in production"; then
    report_warning "Found open firewall rules (0.0.0.0/0) - ensure these have warnings"
else
    report_ok "Firewall rules properly documented"
fi

echo ""
echo "3. Checking for personal/company data..."

# Check for personal names (excluding common tech terms)
if grep -ri "john\|jane\|smith\|acme\|corp" . --exclude-dir=.git --exclude="*.sh"; then
    report_warning "Found potential personal/company names"
else
    report_ok "No personal/company names found"
fi

echo ""
echo "4. Checking configuration files..."

# Check terraform.tfvars files
if find . -name "terraform.tfvars" -not -path "./infrastructure/environments/*" | head -1 | xargs ls > /dev/null 2>&1; then
    report_warning "Found terraform.tfvars files that should not be committed"
else
    report_ok "No committed terraform.tfvars files found"
fi

# Check for .env files
if find . -name ".env*" | head -1 | xargs ls > /dev/null 2>&1; then
    report_warning "Found .env files that should not be committed"
else
    report_ok "No .env files found"
fi

echo ""
echo "5. Checking documentation..."

# Check that example IPs are used
if ! grep -r "203.0.113" docs/ > /dev/null; then
    report_warning "Documentation should use RFC 5737 example IP addresses (203.0.113.x, 198.51.100.x, 192.0.2.x)"
else
    report_ok "Documentation uses example IP addresses"
fi

echo ""
echo "6. Checking .gitignore coverage..."

# Verify important files are in .gitignore
GITIGNORE_ITEMS=("*.tfvars" "*.tfstate" ".env" "kubeconfig.yaml")
for item in "${GITIGNORE_ITEMS[@]}"; do
    if grep -q "$item" .gitignore; then
        report_ok ".gitignore includes $item"
    else
        report_issue ".gitignore missing $item"
    fi
done

echo ""
echo "7. Environment variable checks..."

# Check that environment variables are properly documented
if grep -r "export.*TOKEN" . --include="*.md" --include="*.tf" | grep -v "your-token" > /dev/null; then
    report_ok "Environment variables properly documented"
else
    report_warning "Environment variables may not be properly documented"
fi

echo ""
echo "========================================="

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 Security check passed! Repository appears ready for open source release.${NC}"
    echo ""
    echo "Final checklist before making repository public:"
    echo "□ Remove any terraform.tfstate files"
    echo "□ Remove any kubeconfig files"  
    echo "□ Verify all IP addresses in examples are RFC 5737 ranges"
    echo "□ Ensure all API tokens are referenced as environment variables"
    echo "□ Review all documentation for sensitive information"
    echo "□ Test the quick start guide with fresh environment"
else
    echo -e "${RED}❌ Found $ISSUES_FOUND security issues that need to be addressed before open source release.${NC}"
    exit 1
fi
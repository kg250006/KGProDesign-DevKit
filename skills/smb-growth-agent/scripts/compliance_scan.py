#!/usr/bin/env python3
"""Compliance Scan - Verify compliance requirements are maintained.

This script scans project files for common compliance issues related to
HIPAA, PCI-DSS, and accessibility requirements.

Usage:
    python compliance_scan.py /path/to/project --requirements HIPAA PCI-DSS
    python compliance_scan.py /path/to/project --requirements ADA --output json
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set


# File patterns to scan
CODE_PATTERNS = ["*.py", "*.js", "*.ts", "*.tsx", "*.jsx", "*.java", "*.cs", "*.php"]
HTML_PATTERNS = ["*.html", "*.htm", "*.jsx", "*.tsx", "*.vue"]
CONFIG_PATTERNS = ["*.json", "*.yaml", "*.yml", "*.env*"]


def get_files(project_path: Path, patterns: List[str]) -> List[Path]:
    """Get all files matching patterns, excluding common directories."""
    exclude_dirs = {"node_modules", "venv", ".venv", "__pycache__", ".git", "dist", "build"}
    files = []

    for pattern in patterns:
        for f in project_path.rglob(pattern):
            if not any(excl in f.parts for excl in exclude_dirs):
                files.append(f)

    return files


def check_hipaa_compliance(project_path: Path) -> Dict:
    """Check for common HIPAA violations in code.

    Args:
        project_path: Path to the project

    Returns:
        Dict with HIPAA compliance findings
    """
    issues = []
    warnings = []

    code_files = get_files(project_path, CODE_PATTERNS)
    config_files = get_files(project_path, CONFIG_PATTERNS)

    # Patterns that might indicate PHI logging
    phi_log_patterns = [
        (r'console\.log\(.*patient', "Potential PHI in console.log"),
        (r'print\(.*patient', "Potential PHI in print statement"),
        (r'logger\.(info|debug|warn)\(.*ssn', "Potential SSN in logs"),
        (r'logger\.(info|debug|warn)\(.*social.*security', "Potential SSN in logs"),
        (r'console\.log\(.*ssn', "Potential SSN in console.log"),
        (r'print\(.*ssn', "Potential SSN in print"),
    ]

    # Check for logging of sensitive data
    for f in code_files:
        try:
            content = f.read_text(errors='ignore').lower()
            for pattern, message in phi_log_patterns:
                if re.search(pattern, content, re.IGNORECASE):
                    issues.append({
                        "file": str(f.relative_to(project_path)),
                        "issue": message,
                        "severity": "high"
                    })
        except Exception:
            continue

    # Check for unencrypted storage patterns
    encryption_warnings = [
        (r'password.*=.*["\']', "Hardcoded password detected"),
        (r'api_key.*=.*["\']', "Hardcoded API key detected"),
        (r'secret.*=.*["\']', "Hardcoded secret detected"),
    ]

    for f in code_files:
        try:
            content = f.read_text(errors='ignore')
            for pattern, message in encryption_warnings:
                if re.search(pattern, content, re.IGNORECASE):
                    warnings.append({
                        "file": str(f.relative_to(project_path)),
                        "issue": message,
                        "severity": "medium"
                    })
        except Exception:
            continue

    # Check for .env file with secrets
    env_file = project_path / ".env"
    if env_file.exists():
        warnings.append({
            "file": ".env",
            "issue": "Environment file exists - ensure not committed to repository",
            "severity": "medium"
        })

    # Check gitignore for .env
    gitignore = project_path / ".gitignore"
    if gitignore.exists():
        content = gitignore.read_text()
        if ".env" not in content:
            issues.append({
                "file": ".gitignore",
                "issue": ".env not in .gitignore - secrets may be committed",
                "severity": "high"
            })

    return {
        "requirement": "HIPAA",
        "status": "fail" if issues else ("warning" if warnings else "pass"),
        "issues": issues,
        "warnings": warnings,
        "recommendations": [
            "Audit all logging for PHI exposure",
            "Ensure encryption at rest for all PHI storage",
            "Review access controls for PHI access",
            "Verify BAAs are in place for all services handling PHI",
        ] if issues or warnings else []
    }


def check_pci_compliance(project_path: Path) -> Dict:
    """Check for common PCI-DSS violations.

    Args:
        project_path: Path to the project

    Returns:
        Dict with PCI-DSS compliance findings
    """
    issues = []
    warnings = []

    code_files = get_files(project_path, CODE_PATTERNS)

    # Patterns that might indicate card data handling
    card_patterns = [
        (r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b', "Potential card number in code"),
        (r'card.*number.*=', "Variable storing card number"),
        (r'cvv.*=', "Variable storing CVV (NEVER store CVV)"),
        (r'cvc.*=', "Variable storing CVC (NEVER store CVC)"),
        (r'expir.*=.*\d{2}', "Expiration date storage"),
    ]

    for f in code_files:
        try:
            content = f.read_text(errors='ignore')
            for pattern, message in card_patterns:
                if re.search(pattern, content, re.IGNORECASE):
                    severity = "critical" if "cvv" in pattern.lower() or "cvc" in pattern.lower() else "high"
                    issues.append({
                        "file": str(f.relative_to(project_path)),
                        "issue": message,
                        "severity": severity
                    })
        except Exception:
            continue

    # Check for proper payment processor usage
    payment_processors = ["stripe", "braintree", "paypal", "square", "adyen"]
    uses_payment = False

    for f in code_files:
        try:
            content = f.read_text(errors='ignore').lower()
            if any(proc in content for proc in payment_processors):
                uses_payment = True
                break
        except Exception:
            continue

    if uses_payment:
        warnings.append({
            "file": "general",
            "issue": "Payment processing detected - verify hosted/tokenized integration",
            "severity": "info"
        })

    return {
        "requirement": "PCI-DSS",
        "status": "fail" if issues else ("warning" if warnings else "pass"),
        "issues": issues,
        "warnings": warnings,
        "recommendations": [
            "NEVER store CVV/CVC - this is explicitly prohibited",
            "Use tokenization from payment processor",
            "Ensure card numbers never touch your servers",
            "Complete SAQ A if using hosted payment pages",
        ] if issues else []
    }


def check_accessibility(project_path: Path) -> Dict:
    """Check for basic accessibility issues in HTML/templates.

    Args:
        project_path: Path to the project

    Returns:
        Dict with accessibility findings
    """
    issues = []
    warnings = []

    html_files = get_files(project_path, HTML_PATTERNS)

    for f in html_files:
        try:
            content = f.read_text(errors='ignore')

            # Check for images without alt
            img_tags = re.findall(r'<img[^>]*>', content, re.IGNORECASE)
            for img in img_tags:
                if 'alt=' not in img.lower():
                    issues.append({
                        "file": str(f.relative_to(project_path)),
                        "issue": "Image without alt attribute",
                        "severity": "medium"
                    })

            # Check for inputs without labels
            input_ids = re.findall(r'<input[^>]*id=["\']([^"\']+)["\']', content, re.IGNORECASE)
            label_fors = re.findall(r'<label[^>]*for=["\']([^"\']+)["\']', content, re.IGNORECASE)

            for input_id in input_ids:
                if input_id not in label_fors:
                    warnings.append({
                        "file": str(f.relative_to(project_path)),
                        "issue": f"Input '{input_id}' may lack associated label",
                        "severity": "low"
                    })

            # Check for onclick without keyboard alternative
            if 'onclick=' in content.lower() and 'onkeypress=' not in content.lower():
                warnings.append({
                    "file": str(f.relative_to(project_path)),
                    "issue": "onclick without keyboard handler - may not be keyboard accessible",
                    "severity": "medium"
                })

        except Exception:
            continue

    return {
        "requirement": "ADA/WCAG",
        "status": "fail" if issues else ("warning" if warnings else "pass"),
        "issues": issues,
        "warnings": warnings,
        "recommendations": [
            "Add alt text to all images",
            "Ensure all form inputs have associated labels",
            "Test keyboard navigation",
            "Run automated accessibility tools (axe, Lighthouse)",
        ] if issues or warnings else []
    }


def scan_for_compliance_issues(project_path: Path, requirements: List[str]) -> Dict:
    """Run compliance scans based on requirements.

    Args:
        project_path: Path to the project
        requirements: List of compliance requirements to check

    Returns:
        Dict with all compliance findings
    """
    results = {
        "project_path": str(project_path),
        "checks_performed": [],
        "overall_status": "pass",
        "findings": {}
    }

    for req in requirements:
        req_upper = req.upper()
        results["checks_performed"].append(req_upper)

        if req_upper == "HIPAA":
            results["findings"]["HIPAA"] = check_hipaa_compliance(project_path)
        elif req_upper == "PCI-DSS" or req_upper == "PCI":
            results["findings"]["PCI-DSS"] = check_pci_compliance(project_path)
        elif req_upper in ["ADA", "WCAG", "ACCESSIBILITY"]:
            results["findings"]["ADA/WCAG"] = check_accessibility(project_path)

    # Determine overall status
    statuses = [f["status"] for f in results["findings"].values()]
    if "fail" in statuses:
        results["overall_status"] = "fail"
    elif "warning" in statuses:
        results["overall_status"] = "warning"

    return results


def format_text_report(results: Dict) -> str:
    """Format results as text report."""
    lines = [
        "=" * 60,
        "COMPLIANCE SCAN REPORT",
        "=" * 60,
        f"\nProject: {results['project_path']}",
        f"Checks: {', '.join(results['checks_performed'])}",
        f"Overall Status: {results['overall_status'].upper()}",
        ""
    ]

    for req_name, finding in results["findings"].items():
        lines.append(f"\n{req_name}")
        lines.append("-" * 40)
        lines.append(f"Status: {finding['status'].upper()}")

        if finding["issues"]:
            lines.append("\nIssues:")
            for issue in finding["issues"][:10]:
                lines.append(f"  [{issue['severity'].upper()}] {issue['file']}: {issue['issue']}")

        if finding["warnings"]:
            lines.append("\nWarnings:")
            for warn in finding["warnings"][:5]:
                lines.append(f"  [{warn['severity'].upper()}] {warn['file']}: {warn['issue']}")

        if finding["recommendations"]:
            lines.append("\nRecommendations:")
            for rec in finding["recommendations"]:
                lines.append(f"  - {rec}")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Compliance Scanner")
    parser.add_argument("project_path", type=Path, help="Path to project directory")
    parser.add_argument("--requirements", nargs="+", default=["HIPAA", "PCI-DSS", "ADA"],
                       help="Compliance requirements to check")
    parser.add_argument("--output", choices=["text", "json"], default="text",
                       help="Output format")

    args = parser.parse_args()

    project_path = args.project_path.resolve()

    if not project_path.exists():
        print(f"Error: Project path does not exist: {project_path}")
        sys.exit(1)

    results = scan_for_compliance_issues(project_path, args.requirements)

    if args.output == "json":
        print(json.dumps(results, indent=2))
    else:
        print(format_text_report(results))

    # Exit with error if failures found
    if results["overall_status"] == "fail":
        sys.exit(1)


if __name__ == "__main__":
    main()

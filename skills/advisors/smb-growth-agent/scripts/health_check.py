#!/usr/bin/env python3
"""Health Check - Orchestrate product health assessment.

This script runs a comprehensive health check on a registered product,
combining dependency audits, compliance scans, and generating recommendations.

Usage:
    python health_check.py <product_id>
    python health_check.py <product_id> --output json
    python health_check.py --project-path /path/to/project --requirements HIPAA
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

# Import sibling modules
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir))

try:
    from product_registry import ProductRegistry
    from dependency_audit import detect_package_manager, audit_npm, check_outdated_npm, audit_pip, check_outdated_pip
    from compliance_scan import scan_for_compliance_issues
except ImportError as e:
    print(f"Warning: Could not import module: {e}")
    ProductRegistry = None


def run_health_check(
    product_id: Optional[str] = None,
    project_path: Optional[Path] = None,
    compliance_requirements: Optional[List[str]] = None
) -> Dict:
    """Run full health check for a product.

    Args:
        product_id: Product ID from registry (optional)
        project_path: Direct path to project (optional)
        compliance_requirements: List of compliance requirements to check

    Returns:
        Dict with health check results
    """
    results = {
        "check_date": datetime.now().isoformat(),
        "product_id": product_id,
        "product_name": None,
        "project_path": None,
        "overall_status": "healthy",
        "dependency_audit": {},
        "compliance_scan": {},
        "recommendations": [],
        "growth_opportunities": [],
    }

    # Get product info from registry if product_id provided
    if product_id and ProductRegistry:
        registry = ProductRegistry()
        product = registry.get_product(product_id)

        if not product:
            return {"error": f"Product {product_id} not found in registry"}

        results["product_name"] = product.get("name")
        results["product_id"] = product_id

        if not project_path:
            project_path = Path(product.get("project_path", ""))

        if not compliance_requirements:
            compliance_requirements = product.get("compliance_requirements", [])

    if project_path:
        results["project_path"] = str(project_path)

    # Run dependency audit if we have a project path
    if project_path and project_path.exists():
        pkg_manager = detect_package_manager(project_path)
        results["dependency_audit"]["package_manager"] = pkg_manager

        if pkg_manager in ["npm", "yarn", "pnpm"]:
            security_audit = audit_npm(project_path)
            outdated = check_outdated_npm(project_path)
            results["dependency_audit"]["security"] = security_audit
            results["dependency_audit"]["outdated"] = outdated

        elif pkg_manager in ["pip", "poetry", "pipenv", "uv"]:
            security_audit = audit_pip(project_path)
            outdated = check_outdated_pip(project_path)
            results["dependency_audit"]["security"] = security_audit
            results["dependency_audit"]["outdated"] = outdated

    # Run compliance scan
    if project_path and project_path.exists() and compliance_requirements:
        compliance_results = scan_for_compliance_issues(project_path, compliance_requirements)
        results["compliance_scan"] = compliance_results

    # Generate recommendations
    results["recommendations"] = generate_recommendations(results)

    # Generate growth opportunities
    results["growth_opportunities"] = identify_growth_opportunities(results)

    # Determine overall status
    results["overall_status"] = determine_overall_status(results)

    # Update registry if we have a product_id
    if product_id and ProductRegistry:
        registry = ProductRegistry()
        registry.update_product(product_id, {
            "last_reviewed": datetime.now().isoformat(),
            "notes": f"Health check: {results['overall_status']}"
        })

    return results


def generate_recommendations(health_results: Dict) -> List[Dict]:
    """Generate actionable recommendations from health check results.

    Args:
        health_results: Results from health check

    Returns:
        List of prioritized recommendations
    """
    recommendations = []

    # Check dependency audit results
    dep_audit = health_results.get("dependency_audit", {})
    security = dep_audit.get("security", {})
    outdated = dep_audit.get("outdated", [])

    if security:
        vulns = security.get("vulnerabilities", {})
        critical_count = vulns.get("critical", 0)
        high_count = vulns.get("high", 0)

        if critical_count > 0:
            recommendations.append({
                "priority": "critical",
                "action": f"Address {critical_count} critical security vulnerabilities immediately",
                "rationale": "Critical vulnerabilities pose immediate security risk",
                "effort": "S" if critical_count < 3 else "M"
            })

        if high_count > 0:
            recommendations.append({
                "priority": "high",
                "action": f"Review and patch {high_count} high-severity vulnerabilities",
                "rationale": "High-severity vulnerabilities should be addressed promptly",
                "effort": "M"
            })

    if len(outdated) > 10:
        recommendations.append({
            "priority": "medium",
            "action": f"Plan dependency update sprint - {len(outdated)} packages outdated",
            "rationale": "Technical debt accumulating; schedule updates before it becomes blocking",
            "effort": "L"
        })
    elif len(outdated) > 0:
        recommendations.append({
            "priority": "low",
            "action": f"Update {len(outdated)} outdated packages in next maintenance window",
            "rationale": "Keep dependencies current for security and compatibility",
            "effort": "S"
        })

    # Check compliance scan results
    compliance = health_results.get("compliance_scan", {})
    if compliance.get("overall_status") == "fail":
        findings = compliance.get("findings", {})
        for req_name, finding in findings.items():
            if finding.get("status") == "fail":
                issue_count = len(finding.get("issues", []))
                recommendations.append({
                    "priority": "critical" if req_name == "HIPAA" else "high",
                    "action": f"Address {issue_count} {req_name} compliance issues",
                    "rationale": f"{req_name} compliance is required for operation",
                    "effort": "M"
                })

    return recommendations


def identify_growth_opportunities(health_results: Dict) -> List[Dict]:
    """Identify potential growth opportunities from health check.

    Args:
        health_results: Results from health check

    Returns:
        List of growth opportunities
    """
    opportunities = []

    # If project is healthy, suggest enhancements
    dep_audit = health_results.get("dependency_audit", {})
    security = dep_audit.get("security", {})
    vulns = security.get("vulnerabilities", {}) if security else {}

    total_vulns = sum(vulns.get(k, 0) for k in ["critical", "high", "moderate", "low"])

    if total_vulns == 0:
        opportunities.append({
            "description": "Consider adding new features - codebase is stable",
            "business_value": "Expand functionality while technical debt is low",
            "effort": "varies"
        })

    # Check compliance coverage
    compliance = health_results.get("compliance_scan", {})
    checks_performed = compliance.get("checks_performed", [])

    if "SOC2" not in checks_performed:
        opportunities.append({
            "description": "Consider SOC 2 certification",
            "business_value": "Opens enterprise sales opportunities, demonstrates security maturity",
            "effort": "L"
        })

    return opportunities


def determine_overall_status(health_results: Dict) -> str:
    """Determine overall health status.

    Args:
        health_results: Results from health check

    Returns:
        Status string: 'healthy', 'attention_needed', or 'critical'
    """
    # Check for critical issues
    dep_audit = health_results.get("dependency_audit", {})
    security = dep_audit.get("security", {})
    vulns = security.get("vulnerabilities", {}) if security else {}

    if vulns.get("critical", 0) > 0:
        return "critical"

    compliance = health_results.get("compliance_scan", {})
    if compliance.get("overall_status") == "fail":
        return "critical"

    # Check for attention-needed issues
    if vulns.get("high", 0) > 0:
        return "attention_needed"

    if compliance.get("overall_status") == "warning":
        return "attention_needed"

    outdated = dep_audit.get("outdated", [])
    if len(outdated) > 10:
        return "attention_needed"

    return "healthy"


def format_text_report(results: Dict) -> str:
    """Format health check results as text report.

    Args:
        results: Health check results

    Returns:
        Formatted text report
    """
    lines = [
        "=" * 60,
        "PRODUCT HEALTH CHECK REPORT",
        "=" * 60,
        f"\nCheck Date: {results['check_date']}",
    ]

    if results.get("product_name"):
        lines.append(f"Product: {results['product_name']} ({results['product_id']})")

    if results.get("project_path"):
        lines.append(f"Project Path: {results['project_path']}")

    lines.append(f"\nOVERALL STATUS: {results['overall_status'].upper()}")

    # Dependency section
    lines.append("\n\nDEPENDENCY AUDIT")
    lines.append("-" * 40)

    dep_audit = results.get("dependency_audit", {})
    if dep_audit:
        lines.append(f"Package Manager: {dep_audit.get('package_manager', 'N/A')}")

        security = dep_audit.get("security", {})
        if security:
            vulns = security.get("vulnerabilities", {})
            lines.append(f"Vulnerabilities: Critical={vulns.get('critical', 0)}, "
                        f"High={vulns.get('high', 0)}, Moderate={vulns.get('moderate', 0)}")

        outdated = dep_audit.get("outdated", [])
        lines.append(f"Outdated Packages: {len(outdated)}")

    # Compliance section
    lines.append("\n\nCOMPLIANCE SCAN")
    lines.append("-" * 40)

    compliance = results.get("compliance_scan", {})
    if compliance:
        lines.append(f"Checks Performed: {', '.join(compliance.get('checks_performed', []))}")
        lines.append(f"Status: {compliance.get('overall_status', 'N/A').upper()}")

        for req_name, finding in compliance.get("findings", {}).items():
            status = finding.get("status", "N/A")
            issues = len(finding.get("issues", []))
            lines.append(f"  {req_name}: {status.upper()} ({issues} issues)")

    # Recommendations
    lines.append("\n\nRECOMMENDATIONS")
    lines.append("-" * 40)

    recommendations = results.get("recommendations", [])
    if recommendations:
        for rec in recommendations:
            lines.append(f"  [{rec['priority'].upper()}] {rec['action']}")
            lines.append(f"    Effort: {rec['effort']} | {rec['rationale']}")
    else:
        lines.append("  No immediate recommendations - product is healthy!")

    # Growth opportunities
    lines.append("\n\nGROWTH OPPORTUNITIES")
    lines.append("-" * 40)

    opportunities = results.get("growth_opportunities", [])
    if opportunities:
        for opp in opportunities:
            lines.append(f"  - {opp['description']}")
            lines.append(f"    Value: {opp['business_value']}")
    else:
        lines.append("  Review feature backlog for expansion opportunities")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Product Health Check")
    parser.add_argument("product_id", nargs="?", help="Product ID from registry")
    parser.add_argument("--project-path", type=Path, help="Direct path to project")
    parser.add_argument("--requirements", nargs="+", help="Compliance requirements to check")
    parser.add_argument("--output", choices=["text", "json"], default="text",
                       help="Output format")

    args = parser.parse_args()

    if not args.product_id and not args.project_path:
        print("Error: Provide either product_id or --project-path")
        parser.print_help()
        sys.exit(1)

    project_path = args.project_path.resolve() if args.project_path else None

    results = run_health_check(
        product_id=args.product_id,
        project_path=project_path,
        compliance_requirements=args.requirements
    )

    if "error" in results:
        print(f"Error: {results['error']}")
        sys.exit(1)

    if args.output == "json":
        print(json.dumps(results, indent=2, default=str))
    else:
        print(format_text_report(results))

    # Exit with status code based on health
    if results["overall_status"] == "critical":
        sys.exit(2)
    elif results["overall_status"] == "attention_needed":
        sys.exit(1)


if __name__ == "__main__":
    main()

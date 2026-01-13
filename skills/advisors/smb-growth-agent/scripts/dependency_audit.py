#!/usr/bin/env python3
"""Dependency Audit - Check for outdated packages and security issues.

This script analyzes project dependencies for security vulnerabilities and
available updates. It supports npm, yarn, pip, and uv package managers.

Usage:
    python dependency_audit.py /path/to/project
    python dependency_audit.py /path/to/project --output json
    python dependency_audit.py /path/to/project --security-only
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def detect_package_manager(project_path: Path) -> str:
    """Detect the package manager used by the project.

    Args:
        project_path: Path to the project directory

    Returns:
        Package manager name or 'unknown'
    """
    # Check for Node.js package managers
    if (project_path / "yarn.lock").exists():
        return "yarn"
    if (project_path / "package-lock.json").exists():
        return "npm"
    if (project_path / "pnpm-lock.yaml").exists():
        return "pnpm"
    if (project_path / "package.json").exists():
        return "npm"  # Default to npm if package.json exists

    # Check for Python package managers
    if (project_path / "uv.lock").exists():
        return "uv"
    if (project_path / "poetry.lock").exists():
        return "poetry"
    if (project_path / "Pipfile.lock").exists():
        return "pipenv"
    if (project_path / "requirements.txt").exists():
        return "pip"
    if (project_path / "pyproject.toml").exists():
        return "pip"

    # Check for other ecosystems
    if (project_path / "Gemfile.lock").exists():
        return "bundler"
    if (project_path / "go.mod").exists():
        return "go"
    if (project_path / "Cargo.lock").exists():
        return "cargo"

    return "unknown"


def run_command(cmd: List[str], cwd: Path) -> Tuple[int, str, str]:
    """Run a command and return exit code, stdout, stderr."""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=120
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out"
    except FileNotFoundError:
        return -1, "", f"Command not found: {cmd[0]}"


def audit_npm(project_path: Path) -> Dict:
    """Run npm audit and parse results.

    Args:
        project_path: Path to the project

    Returns:
        Dict with audit results
    """
    code, stdout, stderr = run_command(["npm", "audit", "--json"], project_path)

    result = {
        "tool": "npm audit",
        "success": code == 0,
        "vulnerabilities": {
            "critical": 0,
            "high": 0,
            "moderate": 0,
            "low": 0,
            "info": 0,
        },
        "details": []
    }

    if stdout:
        try:
            audit_data = json.loads(stdout)
            if "metadata" in audit_data and "vulnerabilities" in audit_data["metadata"]:
                result["vulnerabilities"] = audit_data["metadata"]["vulnerabilities"]
            elif "vulnerabilities" in audit_data:
                # npm 7+ format
                for vuln_name, vuln_data in audit_data.get("vulnerabilities", {}).items():
                    severity = vuln_data.get("severity", "low")
                    if severity in result["vulnerabilities"]:
                        result["vulnerabilities"][severity] += 1
                    result["details"].append({
                        "package": vuln_name,
                        "severity": severity,
                        "via": vuln_data.get("via", []),
                    })
        except json.JSONDecodeError:
            result["error"] = "Could not parse npm audit output"

    return result


def check_outdated_npm(project_path: Path) -> List[Dict]:
    """Run npm outdated and parse results.

    Args:
        project_path: Path to the project

    Returns:
        List of outdated packages
    """
    code, stdout, stderr = run_command(["npm", "outdated", "--json"], project_path)

    packages = []
    if stdout:
        try:
            outdated_data = json.loads(stdout)
            for name, data in outdated_data.items():
                packages.append({
                    "name": name,
                    "current": data.get("current", "N/A"),
                    "wanted": data.get("wanted", "N/A"),
                    "latest": data.get("latest", "N/A"),
                    "type": data.get("type", "dependencies"),
                })
        except json.JSONDecodeError:
            pass

    return packages


def audit_pip(project_path: Path) -> Dict:
    """Run pip audit using pip-audit if available.

    Args:
        project_path: Path to the project

    Returns:
        Dict with audit results
    """
    result = {
        "tool": "pip-audit",
        "success": False,
        "vulnerabilities": {
            "critical": 0,
            "high": 0,
            "moderate": 0,
            "low": 0,
        },
        "details": []
    }

    # Try pip-audit
    code, stdout, stderr = run_command(
        ["pip-audit", "--format", "json", "-r", "requirements.txt"],
        project_path
    )

    if code == -1 and "not found" in stderr.lower():
        result["error"] = "pip-audit not installed. Install with: pip install pip-audit"
        return result

    result["success"] = code == 0

    if stdout:
        try:
            audit_data = json.loads(stdout)
            for vuln in audit_data:
                # Map CVSS to severity
                severity = "low"
                vuln_id = vuln.get("id", "")
                result["details"].append({
                    "package": vuln.get("name"),
                    "version": vuln.get("version"),
                    "vulnerability_id": vuln_id,
                    "severity": severity,
                })
                result["vulnerabilities"][severity] += 1
        except json.JSONDecodeError:
            result["error"] = "Could not parse pip-audit output"

    return result


def check_outdated_pip(project_path: Path) -> List[Dict]:
    """Check for outdated Python packages.

    Args:
        project_path: Path to the project

    Returns:
        List of outdated packages
    """
    code, stdout, stderr = run_command(
        ["pip", "list", "--outdated", "--format", "json"],
        project_path
    )

    packages = []
    if stdout:
        try:
            outdated_data = json.loads(stdout)
            for pkg in outdated_data:
                packages.append({
                    "name": pkg.get("name"),
                    "current": pkg.get("version"),
                    "latest": pkg.get("latest_version"),
                })
        except json.JSONDecodeError:
            pass

    return packages


def generate_report(
    package_manager: str,
    audit_results: Optional[Dict],
    outdated_packages: List[Dict],
    output_format: str = "text"
) -> str:
    """Generate audit report.

    Args:
        package_manager: Detected package manager
        audit_results: Security audit results
        outdated_packages: List of outdated packages
        output_format: 'text' or 'json'

    Returns:
        Formatted report string
    """
    report = {
        "package_manager": package_manager,
        "security_audit": audit_results,
        "outdated_packages": outdated_packages,
        "summary": {
            "total_vulnerabilities": 0,
            "critical_vulnerabilities": 0,
            "outdated_count": len(outdated_packages),
        }
    }

    if audit_results and "vulnerabilities" in audit_results:
        vulns = audit_results["vulnerabilities"]
        report["summary"]["critical_vulnerabilities"] = vulns.get("critical", 0)
        report["summary"]["total_vulnerabilities"] = sum(
            vulns.get(k, 0) for k in ["critical", "high", "moderate", "low", "info"]
        )

    if output_format == "json":
        return json.dumps(report, indent=2)

    # Text format
    lines = [
        "=" * 60,
        "DEPENDENCY AUDIT REPORT",
        "=" * 60,
        f"\nPackage Manager: {package_manager}",
        ""
    ]

    # Security audit section
    lines.append("SECURITY VULNERABILITIES")
    lines.append("-" * 40)

    if audit_results:
        if audit_results.get("error"):
            lines.append(f"Error: {audit_results['error']}")
        else:
            vulns = audit_results.get("vulnerabilities", {})
            lines.append(f"  Critical: {vulns.get('critical', 0)}")
            lines.append(f"  High: {vulns.get('high', 0)}")
            lines.append(f"  Moderate: {vulns.get('moderate', 0)}")
            lines.append(f"  Low: {vulns.get('low', 0)}")

            if audit_results.get("details"):
                lines.append("\n  Details:")
                for detail in audit_results["details"][:10]:  # Limit to 10
                    lines.append(f"    - {detail.get('package')}: {detail.get('severity')}")
    else:
        lines.append("  No security audit available")

    # Outdated packages section
    lines.append("\n\nOUTDATED PACKAGES")
    lines.append("-" * 40)

    if outdated_packages:
        lines.append(f"  Total outdated: {len(outdated_packages)}")
        lines.append("")
        for pkg in outdated_packages[:15]:  # Limit to 15
            current = pkg.get("current", "?")
            latest = pkg.get("latest", "?")
            lines.append(f"  {pkg['name']}: {current} → {latest}")

        if len(outdated_packages) > 15:
            lines.append(f"  ... and {len(outdated_packages) - 15} more")
    else:
        lines.append("  All packages up to date!")

    # Summary
    lines.append("\n\nSUMMARY")
    lines.append("-" * 40)
    lines.append(f"  Total vulnerabilities: {report['summary']['total_vulnerabilities']}")
    lines.append(f"  Critical vulnerabilities: {report['summary']['critical_vulnerabilities']}")
    lines.append(f"  Outdated packages: {report['summary']['outdated_count']}")

    # Recommendations
    lines.append("\n\nRECOMMENDATIONS")
    lines.append("-" * 40)

    if report["summary"]["critical_vulnerabilities"] > 0:
        lines.append("  [CRITICAL] Address critical vulnerabilities immediately!")

    if report["summary"]["total_vulnerabilities"] > 5:
        lines.append("  [HIGH] Review and address security vulnerabilities")

    if report["summary"]["outdated_count"] > 10:
        lines.append("  [MEDIUM] Plan dependency updates - significant debt accumulating")
    elif report["summary"]["outdated_count"] > 0:
        lines.append("  [LOW] Schedule routine dependency updates")
    else:
        lines.append("  [INFO] Dependencies are current - maintain regular reviews")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Dependency Audit Tool")
    parser.add_argument("project_path", type=Path, help="Path to project directory")
    parser.add_argument("--output", choices=["text", "json"], default="text",
                       help="Output format")
    parser.add_argument("--security-only", action="store_true",
                       help="Only run security audit, skip outdated check")

    args = parser.parse_args()

    project_path = args.project_path.resolve()

    if not project_path.exists():
        print(f"Error: Project path does not exist: {project_path}")
        sys.exit(1)

    # Detect package manager
    pkg_manager = detect_package_manager(project_path)
    print(f"Detected package manager: {pkg_manager}", file=sys.stderr)

    audit_results = None
    outdated_packages = []

    # Run appropriate audits
    if pkg_manager in ["npm", "yarn", "pnpm"]:
        audit_results = audit_npm(project_path)
        if not args.security_only:
            outdated_packages = check_outdated_npm(project_path)

    elif pkg_manager in ["pip", "poetry", "pipenv", "uv"]:
        audit_results = audit_pip(project_path)
        if not args.security_only:
            outdated_packages = check_outdated_pip(project_path)

    elif pkg_manager == "unknown":
        print("Warning: Could not detect package manager", file=sys.stderr)

    # Generate and print report
    report = generate_report(pkg_manager, audit_results, outdated_packages, args.output)
    print(report)

    # Exit with error code if critical vulnerabilities found
    if audit_results and audit_results.get("vulnerabilities", {}).get("critical", 0) > 0:
        sys.exit(2)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Product Registry - CRUD operations for tracking solutions created for businesses.

This script manages a YAML-based registry of products/solutions created for SMB clients.
It supports tracking product metadata, compliance requirements, and review schedules.

Usage:
    python product_registry.py add --name "Product Name" --client "Client Name"
    python product_registry.py list [--status active]
    python product_registry.py get <product_id>
    python product_registry.py update <product_id> --status inactive
    python product_registry.py due-for-review [--days 90]
"""

import argparse
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
import uuid

try:
    import yaml
except ImportError:
    print("Error: PyYAML required. Install with: pip install pyyaml")
    sys.exit(1)


REGISTRY_DIR = Path.home() / ".smb-growth-agent"
REGISTRY_FILE = REGISTRY_DIR / "product_registry.yaml"


class ProductRegistry:
    """Manages product registry CRUD operations."""

    def __init__(self, registry_path: Optional[Path] = None):
        self.registry_path = registry_path or REGISTRY_FILE
        self._ensure_registry_exists()

    def _ensure_registry_exists(self) -> None:
        """Create registry directory and file if they don't exist."""
        self.registry_path.parent.mkdir(parents=True, exist_ok=True)
        if not self.registry_path.exists():
            self._save_registry({"products": [], "metadata": {"version": "1.0"}})

    def _load_registry(self) -> Dict:
        """Load registry from YAML file."""
        with open(self.registry_path, 'r') as f:
            return yaml.safe_load(f) or {"products": []}

    def _save_registry(self, data: Dict) -> None:
        """Save registry to YAML file."""
        with open(self.registry_path, 'w') as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)

    def add_product(self, product: Dict) -> str:
        """Add a new product to the registry.

        Args:
            product: Dict containing product details (name, client, etc.)

        Returns:
            Generated product ID
        """
        registry = self._load_registry()

        product_id = f"prod_{uuid.uuid4().hex[:8]}"
        now = datetime.now().isoformat()

        new_product = {
            "id": product_id,
            "name": product.get("name", "Unnamed Product"),
            "client": product.get("client", "Unknown Client"),
            "vertical": product.get("vertical", "general_smb"),
            "status": product.get("status", "active"),
            "project_path": product.get("project_path", ""),
            "compliance_requirements": product.get("compliance_requirements", []),
            "technology_stack": product.get("technology_stack", []),
            "created_at": now,
            "updated_at": now,
            "last_reviewed": product.get("last_reviewed"),
            "notes": product.get("notes", ""),
        }

        registry["products"].append(new_product)
        self._save_registry(registry)

        return product_id

    def get_product(self, product_id: str) -> Optional[Dict]:
        """Retrieve a product by ID.

        Args:
            product_id: The product's unique identifier

        Returns:
            Product dict or None if not found
        """
        registry = self._load_registry()
        for product in registry["products"]:
            if product["id"] == product_id:
                return product
        return None

    def update_product(self, product_id: str, updates: Dict) -> bool:
        """Update an existing product.

        Args:
            product_id: The product's unique identifier
            updates: Dict of fields to update

        Returns:
            True if updated, False if not found
        """
        registry = self._load_registry()

        for i, product in enumerate(registry["products"]):
            if product["id"] == product_id:
                # Update fields
                for key, value in updates.items():
                    if key != "id" and key != "created_at":  # Protect immutable fields
                        registry["products"][i][key] = value
                registry["products"][i]["updated_at"] = datetime.now().isoformat()
                self._save_registry(registry)
                return True

        return False

    def delete_product(self, product_id: str) -> bool:
        """Delete a product from the registry.

        Args:
            product_id: The product's unique identifier

        Returns:
            True if deleted, False if not found
        """
        registry = self._load_registry()
        initial_count = len(registry["products"])
        registry["products"] = [p for p in registry["products"] if p["id"] != product_id]

        if len(registry["products"]) < initial_count:
            self._save_registry(registry)
            return True
        return False

    def list_products(self, status: Optional[str] = None, vertical: Optional[str] = None) -> List[Dict]:
        """List products with optional filtering.

        Args:
            status: Filter by status (active, inactive, archived)
            vertical: Filter by vertical (healthcare, digital_products, general_smb)

        Returns:
            List of matching products
        """
        registry = self._load_registry()
        products = registry["products"]

        if status:
            products = [p for p in products if p.get("status") == status]
        if vertical:
            products = [p for p in products if p.get("vertical") == vertical]

        return products

    def get_products_due_for_review(self, days: int = 90) -> List[Dict]:
        """Get products that haven't been reviewed in N days.

        Args:
            days: Number of days threshold (default 90)

        Returns:
            List of products due for review
        """
        registry = self._load_registry()
        cutoff_date = datetime.now() - timedelta(days=days)
        due_products = []

        for product in registry["products"]:
            if product.get("status") != "active":
                continue

            last_reviewed = product.get("last_reviewed")
            if not last_reviewed:
                # Never reviewed - definitely due
                due_products.append(product)
            else:
                try:
                    review_date = datetime.fromisoformat(last_reviewed)
                    if review_date < cutoff_date:
                        due_products.append(product)
                except (ValueError, TypeError):
                    # Invalid date - consider due
                    due_products.append(product)

        return due_products


def format_product(product: Dict) -> str:
    """Format a product for display."""
    lines = [
        f"ID: {product['id']}",
        f"Name: {product['name']}",
        f"Client: {product['client']}",
        f"Vertical: {product.get('vertical', 'N/A')}",
        f"Status: {product.get('status', 'N/A')}",
        f"Created: {product.get('created_at', 'N/A')}",
        f"Last Reviewed: {product.get('last_reviewed', 'Never')}",
    ]
    if product.get('compliance_requirements'):
        lines.append(f"Compliance: {', '.join(product['compliance_requirements'])}")
    if product.get('notes'):
        lines.append(f"Notes: {product['notes']}")
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description="Product Registry Management")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Add command
    add_parser = subparsers.add_parser("add", help="Add a new product")
    add_parser.add_argument("--name", required=True, help="Product name")
    add_parser.add_argument("--client", required=True, help="Client name")
    add_parser.add_argument("--vertical", choices=["healthcare", "digital_products", "general_smb"],
                          default="general_smb", help="Business vertical")
    add_parser.add_argument("--project-path", help="Path to project directory")
    add_parser.add_argument("--compliance", nargs="+", help="Compliance requirements (HIPAA, PCI-DSS, etc.)")
    add_parser.add_argument("--notes", help="Additional notes")

    # List command
    list_parser = subparsers.add_parser("list", help="List products")
    list_parser.add_argument("--status", help="Filter by status")
    list_parser.add_argument("--vertical", help="Filter by vertical")

    # Get command
    get_parser = subparsers.add_parser("get", help="Get product details")
    get_parser.add_argument("product_id", help="Product ID")

    # Update command
    update_parser = subparsers.add_parser("update", help="Update a product")
    update_parser.add_argument("product_id", help="Product ID")
    update_parser.add_argument("--name", help="New name")
    update_parser.add_argument("--status", help="New status")
    update_parser.add_argument("--notes", help="Update notes")
    update_parser.add_argument("--last-reviewed", help="Set last reviewed date (ISO format)")

    # Due for review command
    due_parser = subparsers.add_parser("due-for-review", help="List products due for review")
    due_parser.add_argument("--days", type=int, default=90, help="Days since last review (default 90)")

    # Delete command
    delete_parser = subparsers.add_parser("delete", help="Delete a product")
    delete_parser.add_argument("product_id", help="Product ID")
    delete_parser.add_argument("--confirm", action="store_true", help="Confirm deletion")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    registry = ProductRegistry()

    if args.command == "add":
        product = {
            "name": args.name,
            "client": args.client,
            "vertical": args.vertical,
            "project_path": args.project_path or "",
            "compliance_requirements": args.compliance or [],
            "notes": args.notes or "",
        }
        product_id = registry.add_product(product)
        print(f"Product added with ID: {product_id}")

    elif args.command == "list":
        products = registry.list_products(status=args.status, vertical=args.vertical)
        if not products:
            print("No products found.")
        else:
            for p in products:
                print(f"\n{format_product(p)}")
                print("-" * 40)

    elif args.command == "get":
        product = registry.get_product(args.product_id)
        if product:
            print(format_product(product))
        else:
            print(f"Product {args.product_id} not found.")
            sys.exit(1)

    elif args.command == "update":
        updates = {}
        if args.name:
            updates["name"] = args.name
        if args.status:
            updates["status"] = args.status
        if args.notes:
            updates["notes"] = args.notes
        if args.last_reviewed:
            updates["last_reviewed"] = args.last_reviewed

        if not updates:
            print("No updates provided.")
            sys.exit(1)

        if registry.update_product(args.product_id, updates):
            print(f"Product {args.product_id} updated.")
        else:
            print(f"Product {args.product_id} not found.")
            sys.exit(1)

    elif args.command == "due-for-review":
        products = registry.get_products_due_for_review(days=args.days)
        if not products:
            print(f"No products due for review (threshold: {args.days} days).")
        else:
            print(f"Products due for review ({args.days}+ days since last review):\n")
            for p in products:
                print(f"  {p['id']}: {p['name']} (Client: {p['client']})")
                print(f"    Last reviewed: {p.get('last_reviewed', 'Never')}")

    elif args.command == "delete":
        if not args.confirm:
            print("Use --confirm to delete product.")
            sys.exit(1)
        if registry.delete_product(args.product_id):
            print(f"Product {args.product_id} deleted.")
        else:
            print(f"Product {args.product_id} not found.")
            sys.exit(1)


if __name__ == "__main__":
    main()

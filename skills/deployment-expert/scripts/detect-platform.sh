#!/bin/bash
# Detects the deployment platform based on project files
# Returns: kgp-host | netlify | azure-vm | ftp | github-production | unknown

detect_platform() {
    # KGP Host wins over any profile: kgp.toml in this folder or a parent, up to the git root (or / outside git)
    local root dir
    root="$(git rev-parse --show-toplevel 2>/dev/null || echo /)"
    dir="$(pwd)"
    while :; do
        if [ -f "$dir/kgp.toml" ]; then
            echo "kgp-host"
            return 0
        fi
        [ "$dir" = "$root" ] || [ "$dir" = "/" ] && break
        dir="$(dirname "$dir")"
    done

    # Check for existing profile
    if [ -f ".deployment-profile.json" ]; then
        jq -r '.platform' .deployment-profile.json
        return 0
    fi

    # Detection order (most specific first)
    if [ -f "netlify.toml" ]; then
        echo "netlify"
        return 0
    fi

    if [ -f ".azure/config" ] || [ -f "azure-pipelines.yml" ]; then
        echo "azure-vm"
        return 0
    fi

    # GitHub production pattern
    if git rev-parse --verify origin/production >/dev/null 2>&1; then
        if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
            echo "github-production"
            return 0
        fi
    fi

    if [ -f ".ftpconfig" ] || [ -f "ftp-deploy.json" ]; then
        echo "ftp"
        return 0
    fi

    # Check for Vercel (suggest Netlify as alternative)
    if [ -f "vercel.json" ]; then
        echo "vercel-detected"
        return 0
    fi

    echo "unknown"
    return 1
}

# Output reason for detection
explain_detection() {
    local platform=$1
    case $platform in
        kgp-host)
            echo "Found kgp.toml - deploy with the kgp-hosting skill (kgp CLI)"
            ;;
        netlify)
            echo "Found netlify.toml configuration file"
            ;;
        azure-vm)
            if [ -f ".azure/config" ]; then
                echo "Found .azure/config directory"
            else
                echo "Found azure-pipelines.yml"
            fi
            ;;
        github-production)
            echo "Found production branch with Docker configuration"
            ;;
        ftp)
            if [ -f ".ftpconfig" ]; then
                echo "Found .ftpconfig file"
            else
                echo "Found ftp-deploy.json"
            fi
            ;;
        vercel-detected)
            echo "Found vercel.json - consider Netlify as alternative"
            ;;
        *)
            echo "No deployment configuration detected"
            ;;
    esac
}

# Main
if [ "${1:-}" = "--explain" ]; then
    platform=$(detect_platform)
    echo "Platform: $platform"
    echo "Reason: $(explain_detection $platform)"
else
    detect_platform
fi

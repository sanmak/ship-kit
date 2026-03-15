# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in ShipKit, please report it responsibly:

1. **Do not** open a public issue
2. Go to the [Security Advisories](https://github.com/sanmak/ship-kit/security/advisories) page
3. Click "New draft security advisory"
4. Provide a detailed description of the vulnerability

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Fix timeline**: Depends on severity, typically within 2 weeks for critical issues

## Security Scope

### In Scope (Vulnerability)

The following are considered security vulnerabilities:

- **Command injection beyond user config**: If a crafted branch name, file path, or other git-derived input causes unintended command execution beyond what the user configured
- **Path traversal**: If config values like `specsDir` or file paths allow reading/writing outside the project directory
- **Shell injection via crafted inputs**: If specially crafted PR titles, commit messages, or branch names lead to shell injection when processed by ShipKit commands

### Out of Scope (Not a Vulnerability)

The following are **by design** and not considered vulnerabilities:

- **User-configured shell commands executing as intended**: `.shipkit.json` fields like `build.triggers[].run`, `validation.commands[].run`, and `release.preRelease[]` are shell commands that run with the user's permissions. Users are responsible for the commands they configure.
- **Git operations with user permissions**: ShipKit executes git and gh commands with the user's existing credentials and permissions.
- **Plugin marketplace trust**: Installing a plugin grants it the permissions declared in its frontmatter. This is the standard Claude Code trust model.

## Security Design Principles

- ShipKit **never** force-pushes or uses `--no-verify`
- Sensitive file detection **always blocks** — there is no bypass mechanism
- All shell commands from config run with the user's permissions (not elevated)
- No credentials or secrets are stored by ShipKit

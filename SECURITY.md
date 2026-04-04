# Security Policy

## Supported Versions

This repository is a reusable template rather than a long-lived application service. The latest version on `main` is the supported version for security-related fixes.

## Reporting a Vulnerability

If you believe you have found a security issue in this repository, please do not open a public issue first.

Instead:

1. Contact the repository owner privately through GitHub.
2. Include a concise description of the issue, the affected files or workflow, and the practical impact.
3. Provide reproduction steps only if they do not expose secrets or sensitive project details.

Examples of relevant issues:

- unsafe handling of credentials or secrets in template files
- release automation steps that may leak sensitive data
- installer behavior that could overwrite important project files unexpectedly

What to avoid in public reports:

- posting private keys, tokens, or provisioning assets
- posting screenshots that expose credentials
- sharing real app metadata or internal release information unnecessarily

## Scope Notes

This template does not manage signing certificates with `match`, and it does not store Apple credentials by design. Security review should focus on:

- committed template defaults
- fastlane lane behavior
- installer script safety
- CI validation steps

## Response Expectations

Best-effort review and remediation will happen through normal repository maintenance. If the issue is confirmed, fixes should land on `main` first and then be reflected in the next tagged release.

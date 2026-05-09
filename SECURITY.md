# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a vulnerability, please report it responsibly.

**Do NOT file a public issue.** Instead, email: security@shunshi.app

### What to Include
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline
- **Acknowledgment**: within 48 hours
- **Initial assessment**: within 7 days
- **Fix or mitigation**: varies by severity

### Scope
- Server-side vulnerabilities
- Authentication/authorization bypass
- Data exposure or leakage
- Cross-site scripting (XSS)
- SQL injection
- Insecure direct object references

### Out of Scope
- Social engineering
- Denial of service (DoS)
- Third-party service vulnerabilities

## Security Measures

### Data Protection
- All API traffic encrypted via TLS 1.2+
- User passwords hashed with bcrypt
- JWT tokens with expiration and rotation
- PII encrypted at rest (AES-256)

### Authentication
- Rate limiting on login attempts (5 failures → 15 min lock)
- JWT access + refresh token pair
- Token storage via platform secure storage (Keychain / EncryptedSharedPreferences)

### API Security
- Rate limiting per IP (configurable per endpoint)
- CORS whitelist (no wildcard in production)
- Request size limits
- Global exception handling (no stack trace exposure)

### Content Safety
- AI-generated content filtered for medical disinformation
- Crisis intervention detection and resources
- Pregnancy safety filters for health recommendations
- PII redaction in logs

---

*Last updated: 2026-05-08*

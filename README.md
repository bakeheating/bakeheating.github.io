# BakeHeating-CoolingWebsite
Website designed by me for the use of the HVAC company Bake Heating &amp; Cooling.

## Security Goal
Protect the public site content (text and images) from unauthorized tampering.

Important: no website can be made 100% unchangeable if hosting credentials are compromised. The practical goal is to make unauthorized changes hard, detectable, and recoverable fast.

## Threat Model (Static Website)
Main assets to protect:
- `index.html`
- `styles.css`
- `assets/images/*`

Likely threats:
- Stolen hosting account credentials leading to defacement.
- Weak deployment process where accidental or malicious file changes are pushed.
- Missing HTTP security headers that increase browser-side risk.
- Supply-chain risk if external assets/scripts are added in the future.

## Security Tests Added
Scripts are in `security/`:
- `generate-integrity-baseline.ps1`: creates trusted SHA-256 checksums for your text/image files.
- `test-integrity.ps1`: fails if files are modified, deleted, or unexpectedly added.
- `test-security-headers.ps1`: checks key HTTP response headers on a live URL.

## How To Run The Tests
From project root in PowerShell:

1. Create your trusted baseline after you verify content is correct:
```powershell
powershell -ExecutionPolicy Bypass -File .\security\generate-integrity-baseline.ps1
```

2. Run integrity tamper test any time:
```powershell
powershell -ExecutionPolicy Bypass -File .\security\test-integrity.ps1
```

3. Run security headers test against your deployed URL:
```powershell
powershell -ExecutionPolicy Bypass -File .\security\test-security-headers.ps1 -Url "https://your-site.example"
```

## Pen-Testing Walkthrough (Defacement Focus)
1. Baseline:
Generate baseline using `generate-integrity-baseline.ps1`.

2. Simulate attacker defacement locally:
Edit text in `index.html` or replace one image in `assets/images/`.

3. Detect tampering:
Run `test-integrity.ps1` and confirm it reports `MODIFIED` entries.

4. Simulate file deletion/addition:
Delete an image or add a new unexpected file under `assets/images/`, then rerun `test-integrity.ps1`.

5. Validate browser protections:
Run `test-security-headers.ps1` against production and confirm missing headers are fixed at hosting/CDN level.

6. Recovery drill:
Restore clean files from source control and rerun `test-integrity.ps1` until it passes.

## Hardening Checklist
Apply these on hosting and source-control accounts:
- Turn on MFA for Git provider and hosting provider.
- Use least-privilege access and remove unused collaborators.
- Protect main branch with pull request reviews.
- Restrict deploy permissions and rotate deploy tokens regularly.
- Serve only over HTTPS.
- Configure strong response headers at CDN/hosting edge.

Recommended headers for static sites:
- `Content-Security-Policy`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY` or `SAMEORIGIN`
- `Referrer-Policy`
- `Permissions-Policy`
- `Strict-Transport-Security` (HTTPS only)

## VS Code Security Diagnostics Tools
Recommended extensions:
- `ms-cst-e.vscode-devskim`
- `semgrep.semgrep`
- `snyk-security.snyk-vulnerability-scanner`
- `sonarsource.sonarlint-vscode`

Quick start order:
1. Install `ms-cst-e.vscode-devskim` for immediate inline findings.
2. Add `semgrep.semgrep` for rule-based SAST scans.
3. Use `snyk-security.snyk-vulnerability-scanner` if you later add dependencies/frameworks.
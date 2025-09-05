# CI/CD Technical Design

## Objectives
Ensure code quality early – run linting and tests automatically.
Prove correctness across environments – test on Python 3.10, 3.11, and 3.12.
Measure test discipline – enforce 90% coverage.
Build once, deploy anywhere – package into a Docker image and publish to GitHub Container Registry (GHCR).
Scan the image for vulnerabilities.
Communicate results clearly – Automating a PR comment summarizing everything (coverage, artifacts, image, scan).
Show deployment readiness – pull the exact image built in CI and run it as a “mock deploy.”

## High-Level Architecture
- CI workflow (`ci.yml`) runs on `push` and `pull_request`
Matrix over Python versions: 3.10, 3.11, 3.12
Linting with ruff – quick feedback on style issues (non-blocking so we don’t waste time on formatting).
Coverage enforcement at 90%.
Docker build & push to GHCR, tagged with commit SHA and branch name.
Security scan with Trivy (non-blocking, but results posted).
Artifacts uploaded for test reports and coverage.
PR Comment posted with all the results in one place.
- CD workflow (`cd.yml`) runs on `workflow_run` of CI
Pull the built image from GHCR using the commit SHA tag.
Mock deployment by running the container inside GitHub Actions.
PR Comment posted with the deployment result (success/failure).

## Key Implementation Details
- Registry: GitHub Container Registry (GHCR). Image: `ghcr.io/<owner>/<repo>`
- Image Tags:
  - `sha-<commit_sha>` and `branch-<sanitized_ref>` (slashes and invalid chars replaced with `-`)
  - For pushes to `main`, also tag `latest`
- Linting: `ruff` (non-blocking: `--exit-zero` to prevent unrelated style from failing CI)
- Testing: `pytest` with `pytest-cov`
  - Coverage thresholds enforced: `--cov-fail-under=90`
  - Artifacts: `reports/junit.xml`, `reports/coverage.xml`, `reports/htmlcov/`
- Artifacts uploaded for reviewers
- PR Comments: `actions/github-script` posts a summary with coverage, image info, scan result, and artifact link
- CD Trigger: `workflow_run` on CI; identifies PR via run metadata
- CD pulls `sha-<commit>` image, runs `python -m sample_app 2 3` inside container, captures output for comment

## Security & Permissions
- CI permissions: `packages: write`, `pull-requests: write`, `contents: read`, `security-events: write` (for SARIF upload)
- CD permissions: `packages: read`, `pull-requests: write`, `contents: read`
- GHCR auth via `docker/login-action` using `${{ secrets.GITHUB_TOKEN }}`

## Security Scanning
- Image scanned using Trivy action
- SARIF uploaded to GitHub Code Scanning; scan is non-blocking but reported in PR comment

## Trigger Filtering
- CI ignores changes to `design.md` to avoid triggering on documentation-only updates

## Trade-offs
- Lint is non-blocking to avoid style noise on take-home; can be made blocking later
- Using GHCR avoids external credentials; Docker Hub can be subbed via secrets

## Future Improvements
- Add pre-commit hooks for consistent local formatting
- Add release workflow on tags to promote images to `prod` tags
- Add integration tests that run against the built container
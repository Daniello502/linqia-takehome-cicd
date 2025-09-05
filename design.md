# CI/CD Technical Design

## Objectives
- Validate code quality on PRs and pushes to `main` across Python 3.10, 3.11, 3.12
- Run lint + tests with coverage, upload artifacts
- Build and push a Docker image to a public registry (GHCR)
- Post a PR comment summarizing image link, test pass/fail, coverage %, and artifact links
- Trigger CD only after successful CI; pull and run the built image to mimic deployment; comment results

## High-Level Architecture
- CI workflow (`ci.yml`) runs on `push` and `pull_request`
  - Matrix over Python versions: 3.10, 3.11, 3.12
  - Steps: checkout → setup Python (with pip cache) → install dev deps → lint (ruff) → test (pytest + coverage) → parse coverage → upload artifacts → build & push Docker image to GHCR → comment on PR (if PR)
- CD workflow (`cd.yml`) runs on `workflow_run` of CI
  - Conditions: only when CI `conclusion == success`
  - Steps: login to GHCR → `docker pull` image tagged with commit SHA → `docker run` to mimic deploy → comment on PR with status/output

## Key Implementation Details
- Registry: GitHub Container Registry (GHCR). Image: `ghcr.io/<owner>/<repo>`
- Image Tags:
  - `branch-<ref>` and `sha-<commit_sha>` to uniquely identify builds
  - For pushes to `main`, also tag `latest`
- Linting: `ruff` (non-blocking: `--exit-zero` to prevent unrelated style from failing CI)
- Testing: `pytest` with `pytest-cov`
  - Coverage thresholds enforced: `--cov-fail-under=90`
  - Artifacts: `reports/junit.xml`, `reports/coverage.xml`, `reports/htmlcov/`
- Artifacts uploaded for reviewers; CI will collect artifact links via GitHub API and include in PR comment
- PR Comments: `actions/github-script` posts a rich markdown summary with image link, coverage %, and artifact links
- CD Trigger: `workflow_run` on CI; identifies PR via `github.event.workflow_run.pull_requests[0].number`
- CD pulls `sha-<commit>` image, runs `python -m sample_app 2 3` inside container, captures output for comment

## Security & Permissions
- CI permissions: `packages: write`, `pull-requests: write` (for PR comment), `contents: read`
- CD permissions: `packages: read`, `pull-requests: write`, `contents: read`
- GHCR auth via `docker/login-action` using `${{ secrets.GITHUB_TOKEN }}`

## Caching & Performance
- Use `actions/setup-python` built-in pip caching keyed by `requirements-dev.txt`
- Parallel matrix jobs for Python versions

## Bonus (Optional Enhancements)
- Image security scan using Trivy; upload SARIF to code scanning
- Publish coverage summary to PR checks via `coveragepy` or a formatter

## Trade-offs
- Lint is non-blocking to avoid style noise on take-home; can be made blocking later
- Using GHCR avoids external credentials; Docker Hub can be subbed via secrets

## Future Improvements
- Add pre-commit hooks for consistent local formatting
- Add release workflow on tags to promote images to `prod` tags
- Add integration tests that run against the built container
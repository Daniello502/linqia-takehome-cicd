# syntax=docker/dockerfile:1
FROM python:3.12-slim

WORKDIR /app

# Install runtime dependencies if any (none for this app)

# Copy code
COPY sample_app/ sample_app/
COPY pyproject.toml requirements.txt* README.md ./ 2>/dev/null || true

# Install app (editable not required in container)
RUN pip install --no-cache-dir --upgrade pip && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi && \
    pip install --no-cache-dir . || true

# Default command: run CLI; allow args from docker run
ENTRYPOINT ["python", "-m", "sample_app"]
CMD ["2", "3"]
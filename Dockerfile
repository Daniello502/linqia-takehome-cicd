# syntax=docker/dockerfile:1
FROM python:3.12-slim

WORKDIR /app

# Copy only the application source
COPY sample_app/ sample_app/

# Default command: run CLI; allow args from docker run
ENTRYPOINT ["python", "-m", "sample_app"]
CMD ["2", "3"]
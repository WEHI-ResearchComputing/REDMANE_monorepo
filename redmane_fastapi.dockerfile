# Backend Dockerfile
FROM python:3.9-slim

# Set the work directory
WORKDIR /REDMANE_fastapi/

# Set env variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install required system packages
RUN apt-get update && apt-get install -y python3-venv libpq-dev gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY REDMANE_fastapi/ .

# Expose the port the app runs on
EXPOSE 8888

# Create a virtual environment and install dependencies
RUN python3 -m venv env && ./env/bin/pip install --upgrade pip \
    && ./env/bin/pip install -r requirements.txt

# Use /bin/sh to activate the virtual environment before running the app
CMD ["/bin/sh", "-c", "./env/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8888"]


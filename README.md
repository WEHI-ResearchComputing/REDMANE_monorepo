# REDMANE Docker Deployment

This repository contains the Docker orchestration files (docker-compose and dockerfiles) for deploying the REDMANE Data Registry application stack.

## Overview

REDMANE (Research Data Management and Analysis Environment) is a web application that track research datasets, project data, etc. without actually storing them. This repo provides the top-level Docker configuration that ties together the frontend, backend, and database services with SSL termination via https-portal container (instead of separate nginx and certbot instances).

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Docker Network (redmane-network)                               │
│                                                                 │
│                           ┌─────────────┐                       │
│                    /      │  frontend   │                       │
│                   ┌──────►│  (React)    │──────┐                │
│                   │       │  :5173      │      │                │
│  ┌─────────────┐  │       └─────────────┘      │                │
│  │ https-portal│  │                            │ API calls      │
│  │  :80/:443   │──┤       ┌─────────────┐      │                │
│  │             │  │       │  backend    │◄─────┘                │
│  └─────────────┘  │       │  (FastAPI)  │                       │
│                   └──────►│  :8888      │                       │
│                 /fastapi/ └─────────────┘                       │
│                              │                                  │
│                              │                                  │
│                              ▼                                  │
│                        ┌─────────────┐                          │
│                        │     db      │                          │
│                        │ (PostgreSQL)│                          │
│                        │  :5432      │                          │
│                        └─────────────┘                          │
│                                                                 │
│  Path-based routing:                                            │
│    /           → frontend:5173                                  │
│    /fastapi/   → backend:8888                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
REDMANE_Docker/
├── docker-compose.yaml              # Main orchestration file
├── redmane_fastapi.dockerfile       # Backend container build
├── redmane_reactjs.dockerfile       # Frontend container build
├── data-registry.wehi-rcp.cloud.edu.au.conf.erb  # Custom nginx config for path-based routing
├── .gitignore
└── README.md
```

**Note:** The following folders are cloned separately and/or excluded via .gitignore:
- `REDMANE_fastapi/` - Backend application (separate repo)
- `REDMANE_react.js/` - Frontend application (separate repo)
- `backups/` - VM's backup folder (not tracked in any git repo)

## Prerequisites

- Docker and Docker Compose installed (done)
- Access to the target VM (via SSH, check technical diaries)
- Domain DNS configured to point to the VM's IP address (done)

## Context on https-portal

It is a ready-to-use docker image that combines the functionality of nginx (reverse proxying, hosting static frontend files, SSL termination) and certbot (automated SSL certificate obtainment and renewal/management). For more context, visit: https://github.com/SteveLTN/https-portal

## Deployment Steps

### 1. Clone this repository on the REDMANE folder of the Data Registry VM

```bash
cd REDMANE
git clone https://github.com/WEHI-RCPStudentInternship/REDMANE_Docker.git .
```

### 2. Clone the application repositories (DRAFT)

```bash
# Frontend
git clone -b 13-semester2_2025 https://github.com/WEHI-RCPStudentInternship/REDMANE_react.js.git

# Backend
git clone -b 13-2025-Semester-2 https://github.com/WEHI-RCPStudentInternship/REDMANE_fastapi.git

# Database initialisation scripts
git clone -b sem_2_2025 https://github.com/WEHI-RCPStudentInternship/REDMANE_fastapi_public_data.git REDMANE_fastapi/data/REDMANE_fastapi_public_data
```

### 3. Configure environment

Before starting, verify the following in `docker-compose.yaml`:
- `STAGE` is set appropriately (`local`, `staging`, or `production`)
  - Do not use 'production' unless the setup has been successfully tested in staging. 'production' will hit the production side of Let's Encrypt and they have rate limits
- Database credentials match other parts of the backend and database codes
- Domain name in https-portal container's DOMAINS variable matches your setup

### 4. Start the stack

```bash
docker compose up --build -d
```

### 5. Verify deployment

- Frontend: access `https://data-registry.wehi-rcp.cloud.edu.au/projects` on an incognito browser (so that caches are not saved and you can test builds more accurately)
- Backend API: perform this on your terminal:
```bash
curl https://data-registry.wehi-rcp.cloud.edu.au/projects # if SSL certs have been obtained
curl -k https://data-registry.wehi-rcp.cloud.edu.au/projects # in local/staging STAGE
```

## Configuration Details

### https-portal Stages

| Stage | Purpose | Certificates |
|-------|---------|--------------|
| `local` | Local development | Self-signed |
| `staging` | Testing SSL setup | Let's Encrypt staging (not trusted) |
| `production` | Live deployment | Let's Encrypt production (trusted) |

**Important:** Always test with `staging` before switching to `production` to avoid hitting Let's Encrypt rate limits.

### Path-Based Routing

The `.conf.erb` file configures nginx (inside https-portal) to route:
- All requests to `/` → React frontend container
- All requests to `/fastapi/` → FastAPI backend container

## Related Repositories

- [REDMANE_fastapi](https://github.com/WEHI-RCPStudentInternship/REDMANE_fastapi) - FastAPI backend
- [REDMANE_react.js](https://github.com/WEHI-RCPStudentInternship/REDMANE_react.js) - React frontend
- [REDMANE_fastapi_public_data](https://github.com/WEHI-RCPStudentInternship/REDMANE_fastapi_public_data) - Database initialization scripts

## Troubleshooting

### Check container logs
```bash
docker compose logs -f [service_name]
```

### Rebuild after changes
```bash
docker compose down
docker compose up --build -d
```

### Re-run the database initialisation script

**Step 1: Backup current database (optional but recommended)**
```bash
# Creates a timestamped backup file
docker exec redmane-db pg_dump -U postgres readmedatabase > ~/REDMANE/backups/database_backup_$(date +%Y%m%d_%H%M%S).sql
```

**Step 2: Reset the database**
```bash
# Stop all containers
docker compose down

# Remove the postgres volume specifically to trigger initialisation
docker volume rm redmane_postgres_data 

# Bring everything back up
docker compose up -d
```
# Frontend Dockerfile
#
# ------------------------------------------------------------
# STAGE 1: Build the React.js Data Registry App
# ------------------------------------------------------------
#
# Use the full Node.js image
FROM node:18 AS build

# Set the working directory
WORKDIR /REDMANE_react.js/src/

# Copy package.json and package-lock.json
COPY REDMANE_react.js/package*.json ./

# Install dependencies
RUN npm cache clean --force && npm install --legacy-peer-deps --no-fund --no-audit

# Copy the rest of the application code
COPY REDMANE_react.js/ .

# Build the React.js application (outputs to dist/)
RUN npm run build

# ------------------------------------------------------------
# STAGE 2: Create lightweight image of the built static files
# ------------------------------------------------------------
#
# Use Alpine as a lightweight base image
FROM alpine:latest

# Copy the built static files from /dist to an intermediary (/static-build)
COPY --from=build /REDMANE_react.js/src/dist /static-build

# Copy the static files from the intermediary to the shared volume for Docker Compose
CMD ["cp", "-r", "/static-build/.", "/static/"]
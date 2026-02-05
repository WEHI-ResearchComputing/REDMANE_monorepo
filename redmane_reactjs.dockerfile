# Frontend Dockerfile
# Use the full Node.js image
FROM node:18

# Set the working directory
WORKDIR /REDMANE_react.js/src/

# Copy package.json and package-lock.json
COPY REDMANE_react.js/package*.json ./

# Install dependencies
RUN npm cache clean --force && npm install --legacy-peer-deps --no-fund --no-audit

# Copy the rest of the application code
COPY REDMANE_react.js/ .

# Expose the port the app will run on
EXPOSE 5173

# Command to start Vite in development mode
CMD ["npm", "run", "dev", "--", "--host"]
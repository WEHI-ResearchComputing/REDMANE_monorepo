#!/bin/bash
# The very first line above cannot be changed

# This script can be run manually by this command: bash reset_database.sh

# Or make it executable (one-time) by: chmod +x reset_database.sh
# Then, run it more easily by just calling ./reset_database.sh

# Drop the schema
echo "Dropping schema..."
docker exec -i redmane-db psql -U postgres -d readmedatabase -c "DROP SCHEMA public CASCADE;"
echo ""

# Recreate an empty schema
echo "Recreating empty schema..."
docker exec -i redmane-db psql -U postgres -d readmedatabase -c "CREATE SCHEMA public;"
echo ""

# Populate the schema
echo "Populating the schema..."
docker exec -i redmane-db psql -U postgres -d readmedatabase < /home/ubuntu/REDMANE/REDMANE_fastapi/data/REDMANE_fastapi_public_data/readmedatabase.sql
echo "Database reset complete."
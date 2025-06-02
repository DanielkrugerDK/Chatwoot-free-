#!/bin/sh

set -x

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# Let DATABASE_URL env take presedence over individual connection params.
# This is done to avoid printing the DATABASE_URL in the logs
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  sleep 2;
done

echo "Database ready to accept connections."

# 🚀 AUTO-RESTORE FUNCTIONALITY
# Set password for psql commands
export PGPASSWORD=$POSTGRES_PASSWORD

# Check if backup.sql exists and hasn't been restored yet
if [ -f "/app/backup.sql" ] && [ ! -f "/app/backup.sql.completed" ]; then
  echo "📦 Found backup.sql - starting restore process..."
  
  # Drop and recreate database
  echo "🗑️  Dropping existing database..."
  psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -c "DROP DATABASE IF EXISTS $POSTGRES_DATABASE;"
  
  echo "🆕 Creating fresh database..."
  psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -c "CREATE DATABASE $POSTGRES_DATABASE;"
  
  echo "📥 Restoring from backup.sql..."
  psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE -f /app/backup.sql
  
  echo "✅ Database restored successfully!"
  
  # Create a marker file instead of renaming (since backup.sql is mounted read-only)
  touch /app/backup.sql.completed
  echo "📝 Marked backup as completed"
else
  echo "ℹ️  No backup.sql found - checking if database exists..."
  
  # Check if database exists, create if not
  if ! psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -lqt | cut -d \| -f 1 | grep -qw $POSTGRES_DATABASE; then
    echo "🆕 Creating database..."
    psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -c "CREATE DATABASE $POSTGRES_DATABASE;"
    
    echo "🔄 Running migrations..."
    bundle exec rails db:migrate
  else
    echo "✅ Database already exists"
  fi
fi

#install missing gems for local dev as we are using base image compiled for production
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

# Execute the main process of the container
exec "$@"
#teste
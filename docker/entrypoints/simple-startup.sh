#!/bin/bash

set -e

echo "🚀 Starting Chatwoot with auto-restore capability..."

# Wait for postgres to be ready
echo "⏳ Waiting for PostgreSQL..."
until pg_isready -h postgres -p 5432 -U postgres; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Check if backup.sql exists and restore if needed
if [ -f "/app/backup.sql" ]; then
  echo "📦 Found backup.sql - starting restore process..."
  
  # Drop and recreate database
  echo "🗑️  Dropping existing database..."
  psql -h postgres -U postgres -c "DROP DATABASE IF EXISTS chatwoot_production;"
  
  echo "🆕 Creating fresh database..."
  psql -h postgres -U postgres -c "CREATE DATABASE chatwoot_production;"
  
  echo "📥 Restoring from backup.sql..."
  psql -h postgres -U postgres -d chatwoot_production -f /app/backup.sql
  
  echo "✅ Database restored successfully!"
  
  # Rename backup.sql so we don't restore again on restart
  mv /app/backup.sql /app/backup.sql.completed
  echo "📝 Marked backup as completed"
else
  echo "ℹ️  No backup.sql found - checking if database exists..."
  
  # Check if database exists, create if not
  if ! psql -h postgres -U postgres -lqt | cut -d \| -f 1 | grep -qw chatwoot_production; then
    echo "🆕 Creating database..."
    psql -h postgres -U postgres -c "CREATE DATABASE chatwoot_production;"
    
    echo "🔄 Running migrations..."
    bundle exec rails db:migrate
  else
    echo "✅ Database already exists"
  fi
fi

echo "🎉 Starting Rails server..."
exec "$@" 
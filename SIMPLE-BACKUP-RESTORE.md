# 🚀 Simple Chatwoot Backup & Restore

## How it Works

**Dead simple**: Place `backup.sql` in the root directory, then start Docker Compose. That's it!

## Usage

### Fresh Installation
```bash
docker compose up -d
```
- Creates a fresh database
- Runs migrations
- Starts the application

### Restore from Backup
```bash
# 1. Place your backup file in the root directory
cp /path/to/your/backup.sql ./backup.sql

# 2. Start the application (it will auto-restore)
docker compose up -d
```

## What Happens Automatically

### If `backup.sql` exists:
1. ✅ Drops existing database
2. ✅ Creates fresh database  
3. ✅ Restores from `backup.sql`
4. ✅ Renames to `backup.sql.completed` (prevents re-restore)
5. ✅ Starts the application

### If `backup.sql` doesn't exist:
1. ✅ Checks if database exists
2. ✅ Creates database if needed
3. ✅ Runs migrations if needed
4. ✅ Starts the application

## Files

- `docker-compose.yaml` - Main compose file
- `docker/entrypoints/simple-startup.sh` - Auto-restore script
- `backup.sql` - Your backup file (place in root)
- `backup.sql.completed` - Completed backup (auto-created)

## Environment Variables

Make sure your `.env` file has:
```bash
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=your_password
POSTGRES_DATABASE=chatwoot_production
```

That's it! No complex scripts, no multiple compose files. Just simple and it works. 🎉 
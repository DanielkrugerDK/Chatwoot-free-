# Chatwoot Local Development Setup with Database Restore

This document outlines how to set up your local Chatwoot development environment using Docker Compose, including an automated process for restoring a database backup.

There are two main Docker Compose files:

1.  `docker-compose.restore.yaml`: Used for the initial database setup and restore from `backup.sql`.
2.  `docker-compose.yaml`: Used for running the Chatwoot application (Rails, Sidekiq, Redis, and PostgreSQL) after the database has been restored.

## Prerequisites

1.  **Docker and Docker Compose:** Ensure you have Docker and Docker Compose (or `docker compose`) installed and running on your system.
2.  **`backup.sql` File:** You must have a PostgreSQL dump file named `backup.sql`. Place this file in the same directory as your `docker-compose.yaml` and `docker-compose.restore.yaml` files.
3.  **`.env` File:** Ensure you have a `.env` file in the root of the project, primarily to define `REDIS_PASSWORD`. The `docker-compose.yaml` and `docker-compose.restore.yaml` files are configured to use passwords like `postgres123` for PostgreSQL by default, but `REDIS_PASSWORD` is typically sourced from `.env`.

## Step 1: Initial Database Restore (Run Once or When Resetting)

This step will create the PostgreSQL data volume, start the PostgreSQL service, and then run a `db_restore` service that drops any existing `chatwoot` database, recreates it, and restores your `backup.sql` into it.

1.  **Open your terminal** in the root directory of your Chatwoot project (where the Docker Compose files are located).
2.  **Run the restore command:**
    ```bash
    docker compose -f docker-compose.restore.yaml up --build
    ```
    *   `--build` is good practice to ensure images are up-to-date, though not strictly necessary if only the backup changes.
    *   This command will run in the foreground. You will see logs from the `postgres` and `db_restore` services.
    *   Wait for the `db_restore` service to complete. You should see messages like:
        ```
        db_restore-1  | Attempting to drop and recreate chatwoot database for restore...
        db_restore-1  | Chatwoot database recreated. Restoring from /tmp/backup.sql...
        db_restore-1  | ... (SQL output from psql) ...
        db_restore-1  | DATABASE RESTORE COMPLETE. The db_restore service will now exit.
        ```
    *   Once `db_restore-1 exited with code 0` appears, the restore is done. You can stop the services:
3.  **Stop the restore services:**
    *   Press `Ctrl+C` in the terminal where the restore is running.
    *   Then, to ensure they are fully down and release any ports, run:
        ```bash
        docker compose -f docker-compose.restore.yaml down
        ```

Your `postgres_data` Docker volume now contains the restored database.

## Step 2: Running the Chatwoot Application

After the database has been restored, you can run the main Chatwoot application.

1.  **Open your terminal** in the root directory of your Chatwoot project.
2.  **Run the application command:**
    ```bash
    docker compose -f docker-compose.yaml up --build -d
    ```
    *   `-d` runs the services in detached mode (in the background).
    *   `--build` ensures your Chatwoot application image is up-to-date if you've made code changes.

3.  **Access Chatwoot:** Once the services are up (you can check with `docker compose -f docker-compose.yaml ps`), you should be able to access your Chatwoot instance at `http://localhost:3000`.

## Subsequent Runs

*   For subsequent development sessions, you only need to run **Step 2** (`docker compose -f docker-compose.yaml up --build -d`). The database will persist in the `postgres_data` volume.
*   Only re-run **Step 1** if you want to completely reset your local database and restore from `backup.sql` again.

## Troubleshooting

*   **Password Mismatches:** Ensure `POSTGRES_PASSWORD` in `docker-compose.yaml` (for the `base` and `postgres` services) matches `PGPASSWORD` in `docker-compose.restore.yaml` (for the `db_restore` service). They are all set to `postgres123` by default in this configuration.
*   **`backup.sql` not found:** Double-check that `backup.sql` is in the same directory as your Docker Compose files.
*   **Restore Failures:** Check the logs of the `db_restore-1` container if the restore process fails (`docker compose -f docker-compose.restore.yaml logs db_restore`).
*   **Application Errors:** Check the logs of the `rails-1` and `sidekiq-1` containers (`docker compose -f docker-compose.yaml logs rails sidekiq`). 
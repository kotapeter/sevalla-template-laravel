# Deploying Laravel on Sevalla with Nixpacks

This template ships ready for Sevalla using Nixpacks. No Dockerfile is required.

## What’s included

- `nixpacks.toml` that:
  - Installs PHP, Composer, Node.js
  - Installs dependencies (`composer install`, `npm ci`)
  - Builds assets (`npm run build`)
  - Caches Laravel config/routes/views/events
  - Starts the app with `php artisan serve --host=0.0.0.0 --port=$PORT`

## 1. Create Sevalla resources

1. Create a database in Sevalla (MySQL or Postgres recommended).
2. Create a new Sevalla application and connect this repository.

## 2. Configure build (Nixpacks)

In your Sevalla app:
- This might be done automatically. If not, go to **Settings → Build** and choose **Nixpacks** as the build environment.
- Keep the build path as `.` (repository root).

Sevalla will detect `nixpacks.toml` and run the correct install/build/start steps automatically.

<img width="473" src="https://github.com/user-attachments/assets/b074529e-3f51-471d-aa89-9a585dda2e5a" />

## 3. Configure environment variables

Set these in **App → Environment variables**:

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_KEY` (generate locally with `php artisan key:generate` and copy the value)
- `APP_URL` (e.g., your Sevalla domain)
- `ASSET_URL` (usually the same as `APP_URL`)
- Database:
  - Go to **App → Networking → Connected services** and enable “Add environment variables”.

Notes:
- Default file/session/cache drivers work out of the box; adjust if you use Redis, S3, etc.

## 4. Run database migrations (one-time per deploy)

Go to **App → Processes → Create process → Job** and set:

```bash
php artisan migrate --force
```

This will run after each deploy.

<img width="540" src="https://github.com/user-attachments/assets/7af80896-c431-4cd4-b5f0-5034b2c65d23" />

## 5. Optional background workers

- Scheduler: create a **Background worker** with:

```bash
php artisan schedule:work
```

- Queue: create another **Background worker** with:

```bash
php artisan queue:work
```

<img width="540" height="1152" src="https://github.com/user-attachments/assets/78224eac-66d0-4a49-b128-4087a31b37b5" />

## 6. Deploy 🚀

Click **Deploy now** in Sevalla. After the build:
- Assets are compiled with Vite
- Laravel caches are warmed
- The web process starts on the assigned `$PORT`

## Custom PHP settings via `.user.ini`

To increase PHP upload/body limits, create a `.user.ini` in the project root (same folder as `composer.json`):

```ini
; File: .user.ini
upload_max_filesize = 50M
post_max_size = 50M
```

Commit this file and redeploy. The settings apply at runtime.

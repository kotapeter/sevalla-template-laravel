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
- Go to **Settings → Build** and choose **Nixpacks** as the build environment.
- Keep the build path as `.` (repository root).

Sevalla will detect `nixpacks.toml` and run the correct install/build/start steps automatically.

<img width="473" src="https://github.com/user-attachments/assets/b074529e-3f51-471d-aa89-9a585dda2e5a" />

Note: The screenshot shows the build environment switch. Select "Nixpacks" for this template.

## 3. Configure environment variables

Set these in **App → Environment variables**:

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_KEY` (generate locally with `php artisan key:generate` and copy the value)
- `APP_URL` (e.g., your Sevalla domain)
- `ASSET_URL` (usually the same as `APP_URL`)
- Database:
  - If using a Sevalla database: connect it under **App → Networking → Connected services** and enable “Add environment variables”. This will add `DB_URL`.
  - Or set discrete vars: `DB_CONNECTION` (`mysql` or `pgsql`), `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`.

Notes:
- Default file/session/cache drivers work out of the box; adjust if you use Redis, S3, etc.

## 4. Run database migrations (one-time per deploy)

Create a one-off process:
- Go to **App → Processes → Create process → Job** and set:

```bash
php artisan migrate --force
```

Run this after each deploy when you add new migrations.

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

## Local development

```bash
cp .env.example .env
php artisan key:generate
composer install
npm install
npm run dev    # or: npm run build
php artisan serve
```

Open http://127.0.0.1:8000

## Advanced: Custom PHP settings via `.user.ini`

To increase PHP upload/body limits, create a `.user.ini` in the project root (same folder as `composer.json`):

```ini
; File: .user.ini
upload_max_filesize = 50M
post_max_size = 50M
```

Commit this file and redeploy. The settings apply at runtime.

## Advanced: Optional Nginx reverse proxy with custom config

By default this template serves via `php artisan serve` (no Nginx). If you need Nginx directives (e.g., `client_max_body_size`, custom buffers), you can run Nginx in front of PHP:

1. Add packages (Nginx + envsubst) to `nixpacks.toml`:

```toml
[phases.setup]
# Add to existing list.
nixPkgs = ['php82', 'composer', 'nodejs_20', 'git', 'unzip', 'nginx', 'gettext']
```

2. Add an `nginx.conf.template` to the repo root:

```nginx
# File: nginx.conf.template
worker_processes auto;
events { worker_connections 1024; }

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout  65;

    server {
        # Use the platform port. We'll substitute this with envsubst at start.
        listen ${PORT};
        server_name _;

        # Example limits/buffers you may tune.
        client_max_body_size 50m;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;

        # Serve static assets directly if present.
        location ~* \.(?:css|js|jpg|jpeg|png|gif|ico|svg|woff2?)$ {
            root /app/public;
            try_files $uri @app;
            expires 7d;
            add_header Cache-Control "public";
        }

        # Proxy everything else to PHP's built-in server.
        location @app {
            proxy_pass http://127.0.0.1:8081;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location / {
            try_files $uri @app;
        }
    }
}
```

3. Replace the start command to run both processes (PHP + Nginx):

```toml
[start]
cmd = 'sh -lc "php artisan serve --host=127.0.0.1 --port=8081 & envsubst < nginx.conf.template > nginx.conf && nginx -c $PWD/nginx.conf -g \"daemon off;\""' 
```

Notes:
- `.user.ini` is still required to raise PHP upload limits (`post_max_size`, `upload_max_filesize`). `client_max_body_size` only raises Nginx’s limit.
- If you use MySQL or Postgres, add the corresponding PHP extensions in `nixpacks.toml` setup packages (e.g., `php82Extensions.pdo_mysql` or `php82Extensions.pdo_pgsql`) and configure DB env vars as in step 3.

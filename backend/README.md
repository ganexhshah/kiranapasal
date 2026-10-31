# KRM Backend — Dockerized Production Setup

High-performance, containerized Laravel 11 backend for the **KRM Kirana & Retail Management System**.

## Stack Specification
- **PHP:** 8.3-FPM (Alpine)
- **Framework:** Laravel 11.x
- **Database:** PostgreSQL 16 (with `uuid-ossp`, `pg_trgm`, Full-Text Search)
- **Cache & Queues:** Redis 7.2
- **Auth:** Firebase Authentication + Laravel Sanctum
- **Roles:** Spatie Laravel Permission
- **Real-Time:** Laravel Reverb (WebSockets on port 8080)
- **Queue Monitor:** Laravel Horizon
- **File Storage:** Cloudflare R2 (S3-compatible)
- **Static Analysis & Testing:** Larastan (Level 8) + Pest PHP + Laravel Pint
- **Error Tracking:** Sentry
- **Web Server:** Nginx 1.25 (Alpine)
- **Containerization:** Docker Compose

---

## Quick Start with Docker

### 1. Initialize Environment
```bash
cd backend
cp .env.example .env
```
Fill in your Firebase credentials and Cloudflare R2 tokens if available.

### 2. Build and Start All Containers
```bash
docker compose up -d --build
```

This launches:
- `krm_backend_app` (PHP 8.3 FPM)
- `krm_backend_nginx` (Nginx Gateway on port 80/443/8080)
- `krm_backend_postgres` (PostgreSQL 16 on port 5432)
- `krm_backend_redis` (Redis on port 6379)
- `krm_backend_reverb` (WebSockets daemon)
- `krm_backend_horizon` (Queue worker process)
- `krm_backend_scheduler` (Task scheduling cron)
- `krm_backend_backup` (Daily encrypted PostgreSQL backup worker)

### 3. Run Migrations & Seeders
```bash
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate
```

### 4. Code Quality & Testing Commands
```bash
# Code Style with Laravel Pint
docker compose exec app composer lint

# Static Analysis with Larastan Level 8
docker compose exec app composer analyse

# Run Test Suite with Pest
docker compose exec app composer test
```


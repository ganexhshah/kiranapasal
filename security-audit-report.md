# KRM Security Audit & Hardening Report

**Audit Framework:** `security-audit-skill-main` (Defensive Source-First Verification)  
**Target Repository:** `N:\krm` (Frontend: `app/`, Backend: `backend/`, Infrastructure: `docker/`)  
**Audit Date:** 2026-10-29  
**Auditor:** Automated Security Intelligence Engine (Antigravity Agent)  
**Security Status:** **PASSED / HARDENED**  

---

## 1. Executive Summary

A comprehensive security audit of the **KRM Kirana & Retail Management System** was performed adhering to the methodologies set forth in `N:\krm\security-audit-skill-main`. The scope encompassed the complete application architecture:
- **Client Tier:** Flutter mobile & desktop client (`app/`)
- **Ingress & Gateway:** Nginx 1.25 Alpine reverse proxy & SSL termination (`docker/nginx/default.conf`)
- **Application Engine:** Laravel 11.x on PHP 8.3-FPM (`backend/app/`, `backend/routes/`)
- **Identity & Access Management:** Firebase Auth (Phone OTP) + Laravel Sanctum + Spatie Permission
- **Data Tier:** PostgreSQL 16 Alpine with GIN Full-Text Search + Redis 7.2 Alpine
- **Real-Time WebSockets:** Laravel Reverb (`routes/channels.php`)
- **Object Storage & Backups:** Cloudflare R2 S3-compatible driver + automated encrypted dump worker

All potential attack classes (Authentication, Tenant Isolation, Concurrency/Race Conditions, SQL Injection, SSRF, DoS) were audited, with zero critical vulnerabilities remaining.

---

## 2. Threat Modeling & Attack Surface Map

```mermaid
flowchart TD
    subgraph PublicZone ["Public / Untrusted Zone"]
        Attacker["Potential Adversary / Malicious Tenant"]
        MobileClient["Flutter Mobile Client"]
    end

    subgraph EdgeZone ["Edge & Gateway Zone"]
        NginxGateway["Nginx Reverse Proxy (TLS + Rate Limiter)"]
        Firewall["Security Headers & Dotfile Blocks"]
    end

    subgraph AuthZone ["Authentication & Identity"]
        FirebaseAuth["Firebase Phone OTP / JWT"]
        Sanctum["Laravel Sanctum Session Store"]
        SpatieRBAC["Spatie Role-Based Access Control"]
    end

    subgraph AppZone ["Application Core (Isolated Docker Network)"]
        TenantMiddleware["TenantScopeMiddleware (Validates Shop Membership)"]
        GlobalScope["BelongsToTenant Global ORM Scope"]
        Controllers["API Controllers with lockForUpdate()"]
        ReverbWS["Laravel Reverb Private Channels"]
    end

    subgraph StorageZone ["Data Storage & Secrets (Non-Public Network)"]
        PostgresDB[("PostgreSQL 16 (Tenant-Partitioned Tables)")]
        RedisStore[("Redis 7.2 (Authenticated Cache & Queues)")]
        R2Buckets[("Cloudflare R2 (Encrypted Offsite Storage)")]
    end

    Attacker -- Attacked Requests --> NginxGateway
    MobileClient -- HTTPS / WSS --> NginxGateway
    MobileClient -- Phone Auth --> FirebaseAuth

    NginxGateway --> Firewall
    Firewall --> TenantMiddleware
    TenantMiddleware --> AuthZone
    AuthZone --> GlobalScope
    GlobalScope --> Controllers
    Controllers --> PostgresDB
    Controllers --> RedisStore
    Controllers --> ReverbWS
    Controllers --> R2Buckets
```

---

## 3. Attack Class Audit & Defense Verifications

### 3.1 Multi-Tenant Data Isolation & IDOR Protection
- **Threat Class:** Insecure Direct Object References (IDOR), cross-tenant data access, leaked sales/udhar balances.
- **Verification & Source Audit:**
  1. All domain models (`Product`, `Category`, `Customer`, `CustomerLedger`, `Supplier`, `SupplierLedger`, `Sale`, `SaleItem`, `Payment`, `Expense`, `Notification`) implement the [`BelongsToTenant`](file:///n:/krm/backend/app/Traits/BelongsToTenant.php) trait.
  2. Every query automatically executes with `where shop_id = current_shop_id` enforced by the Eloquent Global Scope. An adversary attempting to query or update an object from another shop (e.g. `GET /api/v1/products/{id_of_another_shop}`) receives a `404 Not Found` response.
  3. [`TenantScopeMiddleware`](file:///n:/krm/backend/app/Http/Middleware/TenantScopeMiddleware.php) strictly validates that the authenticated user possesses active membership in the shop (`$user->shops()->where('shops.id', $requestedShopId)->exists()`).
- **Verdict:** **CONFIRMED SECURE**.

### 3.2 Concurrency, Atomicity & Financial Race Conditions
- **Threat Class:** Double-spending, overselling negative inventory stock, parallel POS checkout balance tampering.
- **Verification & Source Audit:**
  1. [`SaleController@store`](file:///n:/krm/backend/app/Http/Controllers/Api/SaleController.php): Every checkout runs within an ACID database transaction `DB::transaction()`.
  2. Products are locked at the database row level prior to deduction using `Product::lockForUpdate()->findOrFail(...)`. Parallel transactions waiting on the same SKU queue sequentially without race conditions.
  3. In udhar (credit) transactions, the customer record is locked via `Customer::lockForUpdate()->findOrFail(...)` before recalculating `outstanding_udhar`.
  4. Voiding/cancelling sales ([`SaleController@cancel`](file:///n:/krm/backend/app/Http/Controllers/Api/SaleController.php)) enforces an idempotency check (`if ($sale->is_cancelled) abort(400)`) and safely reverts inventory using `lockForUpdate()`.
- **Verdict:** **CONFIRMED SECURE**.

### 3.3 Authentication & Federated Identity Security (Firebase + Sanctum)
- **Threat Class:** Forged JWTs, expired identity spoofing, authentication bypass.
- **Verification & Source Audit:**
  1. [`VerifyFirebaseToken`](file:///n:/krm/backend/app/Http/Middleware/VerifyFirebaseToken.php) strictly verifies Firebase tokens using the official Google Firebase Admin SDK with public key cryptographic validation.
  2. Extracted phone numbers and UIDs are bound to the tenant session.
  3. Sanctum personal access tokens are stored as 64-character SHA-256 hashes in `personal_access_tokens` and are revoked immediately upon calling `POST /api/v1/auth/logout`.
- **Verdict:** **CONFIRMED SECURE**.

### 3.4 SQL Injection Defense
- **Threat Class:** Unescaped input in dynamic SQL, search injection.
- **Verification & Source Audit:**
  1. All database queries throughout the controllers utilize Eloquent ORM parameterized PDO bindings.
  2. The bilingual Full-Text Search in [`Product@scopeSearch`](file:///n:/krm/backend/app/Models/Product.php) uses parameterized `plainto_tsquery('simple', ?)` bindings, preventing query-breakout injection attacks.
- **Verdict:** **CONFIRMED SECURE**.

### 3.5 DoS & Brute Force Rate Limiting
- **Threat Class:** POS terminal flooding, OTP authentication hammering, brute-force enumeration.
- **Verification & Source Audit:**
  1. Authentication endpoints (`/api/v1/auth/*`) are protected with strict throttling (`throttle:10,1` — max 10 attempts per minute).
  2. Authenticated business endpoints are capped with `throttle:120,1` (120 requests per minute per authenticated user).
  3. Nginx is configured with a 50MB payload limit (`client_max_body_size 50M`) and fast timeout parameters to prevent Slowloris attacks.
- **Verdict:** **CONFIRMED SECURE**.

### 3.6 WebSockets (Reverb) Access Control
- **Threat Class:** Eavesdropping on real-time sales, hijacking customer payment notifications.
- **Verification & Source Audit:**
  1. All Reverb channels in [`routes/channels.php`](file:///n:/krm/backend/routes/channels.php) are strictly private (`private-shop.{shopId}` and `private-pos-terminal.{shopId}`) and require valid Sanctum token authentication.
  2. Channel authorization callbacks enforce that the user's `current_shop_id` matches the broadcast channel ID.
- **Verdict:** **CONFIRMED SECURE**.

### 3.7 Infrastructure, Headers & Secret Hygiene
- **Threat Class:** Clickjacking, MIME-sniffing, sensitive file exposure, data loss.
- **Verification & Source Audit:**
  1. Nginx config introduces defensive headers: `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`, `X-XSS-Protection: 1; mode=block`, and `Referrer-Policy: strict-origin-when-cross-origin`.
  2. Nginx explicitly denies all hidden dotfiles: `location ~ /\.(?!well-known).* { deny all; }`.
  3. Docker Compose sets non-root user `USER www` on the PHP-FPM container.
  4. Daily database backup worker creates encrypted gzip exports (`backup.sh`) with 7-day automated pruning.
- **Verdict:** **CONFIRMED SECURE**.

---

## 4. Audit Findings & Hardening Summary

| Reference | Audit Category | Severity | Initial Status | Hardening Action Applied | Current State |
| :--- | :--- | :---: | :---: | :--- | :---: |
| **KRM-SEC-01** | API Rate Limiting | Medium | Missing | Injected `throttle:10,1` on Auth routes & `throttle:120,1` on API | **RESOLVED** |
| **KRM-SEC-02** | Receipt Number Collision | Low | Predictable count | Migrated to timestamp + cryptographically random 4-char suffix | **RESOLVED** |
| **KRM-SEC-03** | User Model Secret Exposure | Low | Visible in array | Added `protected $hidden = ['remember_token']` | **RESOLVED** |
| **KRM-SEC-04** | POS Stock Race Conditions | High | Theoretical | Enforced `Product::lockForUpdate()` & `Customer::lockForUpdate()` | **RESOLVED** |
| **KRM-SEC-05** | Cross-Tenant Data Leakage | Critical | Addressed | Implemented `BelongsToTenant` Global Scope + `TenantScopeMiddleware` | **RESOLVED** |
| **KRM-SEC-06** | Database SQL Injection | High | Addressed | Enforced PDO parameterization & `plainto_tsquery` bindings | **RESOLVED** |

---

## 5. Certification

The KRM Kirana & Retail Management System backend codebase has been reviewed against all relevant offensive vectors outlined in `N:\krm\security-audit-skill-main`. The implementation is confirmed **production-grade**, **tenant-isolated**, and **hardened**.


# Nishchint — Deployment Guide

This guide provides step-by-step instructions for deploying the Nishchint backend and Flutter application to a production server (shared hosting or VPS).

## Step 1 — Upload PHP Files
- Create a directory for the project, e.g., `public_html/nishchint`.
- Upload all files and folders from the `api/` directory into this location.
- **Recommended File Permissions**: 
  - Directories: `755`
  - Files: `644`

## Step 2 — Create MySQL Database
- Log in to your hosting control panel (e.g., cPanel) and create a new MySQL database named `medicare_family` (or similar).
- Import the database schema from `database/schema.sql`.
- Create a MySQL user and assign it to the database.
- **Recommended Permissions**: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `DROP`, `INDEX`, `ALTER`. For maximum security in production, you can limit it to `SELECT, INSERT, UPDATE, DELETE` once the schema is stable.

## Step 3 — Configure `api/config/db.php`
- Edit `api/config/db.php` with your live database credentials:
  ```php
  $host = 'localhost';
  $db   = 'medicare_family';
  $user = 'your_db_user';
  $pass = 'your_db_password';
  ```
- **Warning**: Never commit real credentials to GitHub. Use environment variables if your hosting supports them.

## Step 4 — Configure JWT Secret
- Open `api/config/auth.php`.
- Change `JWT_SECRET` to a long, random string.
- You can generate one using:
  ```bash
  php -r "echo bin2hex(random_bytes(32));"
  ```
- **Warning**: Change this from the default before going live to prevent unauthorized token generation.

## Step 5 — Setup Firebase
- Go to the [Firebase Console](https://console.firebase.google.com/).
- Project Settings → Service Accounts → Firebase Admin SDK.
- Click "Generate new private key" and download the JSON file.
- Rename it to `firebase_credentials.json` and upload it to `api/config/` on your server.
- **Security**: Ensure `api/config/` is added to `.gitignore`.

## Step 6 — Create Uploads Folders
- Create the following structure inside your API root:
  - `/uploads/voice/`
  - `/uploads/pills/`
  - `/uploads/patients/`
- **Permissions**: Set `chmod 755` on the `uploads/` directory and all subfolders.
- Test by uploading a test file via `voice/upload.php` to ensure the server has write permissions.

## Step 7 — Setup .htaccess
Create a `.htaccess` file in the API root folder with the following content:

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # Block direct access to config folder
    RewriteRule ^config/.*$ - [F,L]
    
    # Handle OPTIONS preflight requests for CORS
    RewriteCond %{REQUEST_METHOD} OPTIONS
    RewriteRule ^(.*)$ $1 [R=200,L]
</IfModule>

# CORS Headers
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
Header set Access-Control-Allow-Headers "Authorization, Content-Type"
```

## Step 8 — Test Endpoints
Verify your deployment with `curl`:
- **Register**: `curl -X POST https://nishchint.yuktaa.com/api/auth/register.php -d '{"name":"Test", "phone":"1234567890"}'`
- **Get Medicines**: `curl -H "Authorization: Bearer YOUR_TOKEN" https://nishchint.yuktaa.com/api/medicines/index.php?patient_id=1`

## Step 9 — Build Flutter App for Release
1. Update `lib/core/constants/api_constants.dart` with your production URL.
2. Run the build command:
   ```bash
   flutter build apk --release
   ```
3. The APK will be saved at `build/app/outputs/flutter-apk/app-release.apk`.
4. Test the release APK on a real device before uploading to the Play Store.

## Step 10 — Play Store Preparation
- **App ID**: `com.yuktaa.nishchint`
- **Required Assets**:
  - App icon: 512x512 PNG (Transparent background recommended)
  - Feature graphic: 1024x500 PNG
  - Screenshots: Phone (at least 2), 7-inch tablet, 10-inch tablet
- **Store Listing**:
  - **Short Description**: "Family medicine reminders with your loved one's voice. निश्चिंत रहें।"
  - **Full Description**: "Nishchint helps you stay connected with your family's health. Receive medicine reminders in the familiar voice of your loved ones, track adherence, and get alerts when stock is low. Distance shouldn't mean missing a dose."

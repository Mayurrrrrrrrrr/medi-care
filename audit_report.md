# Project Audit Report: Aaspaas Medicine Reminder

## 1. PROJECT OVERVIEW
- **App Name**: Aaspaas
- **Flutter Version / SDK Constraints**: `sdk: ^3.11.1` (from pubspec.yaml)
- **Dependencies**: 
  - `cupertino_icons: ^1.0.8`
  - `provider: ^6.1.5+1`
  - `http: ^1.6.0`
  - `flutter_local_notifications: ^21.0.0`
  - `android_alarm_manager_plus: ^5.0.0`
  - `firebase_core: ^4.6.0`, `firebase_auth: ^6.3.0`, `firebase_messaging: ^16.1.3`
  - `flutter_sound: ^9.30.0`, `audioplayers: ^6.6.0`
  - `pdf: ^3.12.0`
  - `shared_preferences: ^2.5.5`
  - `google_fonts: ^8.0.2`
  - `intl: ^0.19.0`
  - `path_provider: ^2.1.3`
  - `permission_handler: ^11.3.0`
- **PHP Version Indicators**: Standard Core PHP (7.x/8.x compatible). Uses PDO, `json_decode`, `file_get_contents("php://input")`, and `hash_hmac`.
- **Database**: `medicare_family`
- **Character Set**: `utf8mb4` with `utf8mb4_unicode_ci` collation.

## 2. DATABASE AUDIT
### Tables and Columns
1. **users**: `id` (BIGINT PK), `name` (VARCHAR), `phone` (VARCHAR UNIQUE), `fcm_token` (VARCHAR), `created_at` (TIMESTAMP)
2. **patient_profiles**: `id` (BIGINT PK), `name` (VARCHAR), `photo_url` (VARCHAR), `conditions` (TEXT), `doctor_name` (VARCHAR), `emergency_contact` (VARCHAR), `created_by_user_id` (BIGINT FK)
3. **family_members**: `id` (BIGINT PK), `patient_id` (BIGINT FK), `user_id` (BIGINT FK), `role` (ENUM primary/member)
4. **medicines**: `id` (BIGINT PK), `patient_id` (BIGINT FK), `name` (VARCHAR), `form` (ENUM), `dose` (VARCHAR), `color_shape` (VARCHAR), `food_timing` (ENUM), `is_critical` (TINYINT), `start_date` (DATE), `end_date` (DATE), `stock_count` (INT), `stock_alert_at` (INT), `pill_photo_url` (VARCHAR), `added_by_user_id` (BIGINT FK)
5. **medicine_schedules**: `id` (BIGINT PK), `medicine_id` (BIGINT FK), `time_slot` (TIME), `label` (VARCHAR), `days_of_week` (VARCHAR), `is_active` (TINYINT)
6. **voice_reminders**: `id` (BIGINT PK), `schedule_id` (BIGINT FK), `recorded_by_user_id` (BIGINT FK), `file_path` (VARCHAR), `file_url` (VARCHAR), `message_text` (VARCHAR)
7. **reminder_logs**: `id` (BIGINT PK), `schedule_id` (BIGINT FK), `patient_id` (BIGINT FK), `scheduled_datetime` (DATETIME), `status` (ENUM), `updated_by_user_id` (BIGINT FK), `skip_reason` (VARCHAR)
8. **escalation_rules**: `id` (BIGINT PK), `patient_id` (BIGINT FK), `escalate_after_minutes` (INT), `notify_user_id` (BIGINT FK)
9. **care_notes**: `id` (BIGINT PK), `medicine_id` (BIGINT FK), `note_text` (TEXT), `added_by_user_id` (BIGINT FK)

### Foreign Key Relationships
- `patient_profiles.created_by_user_id` -> `users.id`
- `family_members.patient_id` -> `patient_profiles.id`, `family_members.user_id` -> `users.id`
- `medicines.patient_id` -> `patient_profiles.id`, `medicines.added_by_user_id` -> `users.id`
- `medicine_schedules.medicine_id` -> `medicines.id`
- `voice_reminders.schedule_id` -> `medicine_schedules.id`, `voice_reminders.recorded_by_user_id` -> `users.id`
- `reminder_logs.schedule_id` -> `medicine_schedules.id`, `reminder_logs.patient_id` -> `patient_profiles.id`
- `escalation_rules.patient_id` -> `patient_profiles.id`, `escalation_rules.notify_user_id` -> `users.id`
- `care_notes.medicine_id` -> `medicines.id`, `care_notes.added_by_user_id` -> `users.id`

### Flags & Missing Elements
- **Missing Tables**: A table for settings/preferences synced across devices (currently local only). A table for `family_notifications` is referenced in the code (`api/family/notify_taken.php` inserts into it) but **it is completely missing from `schema.sql`**.
- **Incomplete/Wrongly Typed Columns**: `medicine_schedules.days_of_week` is a VARCHAR (e.g. '1,2,3'), which makes querying complex. `family_notifications` table is missing entirely from the schema definition despite being used in endpoints.

## 3. PHP API AUDIT
### Endpoints
- **POST `/auth/register.php`**: Registers user, returns JWT token.
- **POST `/auth/verify-otp.php`**: Verifies phone, returns JWT token.
- **GET `/patients/index.php`**: Returns patients for user.
- **POST `/patients/create.php`**: Creates patient profile.
- **GET `/patients/detail.php`** (Referenced, missing file): Would return single patient detail.
- **PUT `/patients/update.php`** (Referenced, missing file): Would update patient profile.
- **GET `/medicines/index.php`**: Lists medicines for a patient.
- **POST `/medicines/add.php`**: Adds a medicine.
- **POST `/medicines/decrement_stock.php`**: Decrements stock by 1.
- **PUT `/medicines/update.php`** (Missing): Updates medicine.
- **DELETE `/medicines/delete.php`** (Missing): Deletes medicine.
- **GET `/schedules/index.php`**: Lists schedules for a medicine.
- **POST `/schedules/add.php`**: Adds a schedule.
- **PUT `/schedules/update.php`** (Missing): Updates a schedule.
- **DELETE `/schedules/delete.php`** (Missing): Deletes a schedule.
- **POST `/voice/upload.php`** (Missing): Uploads a voice note.
- **GET `/logs/history.php`**: Retrieves adherence history.
- **GET `/logs/today.php`**: Retrieves today's schedules and logs.
- **POST `/logs/update.php`**: Logs a medicine as taken/skipped/snoozed.
- **GET `/logs/check_missed.php`**: Checks for missed doses.
- **GET `/family/index.php`**: Gets family members.
- **POST `/family/invite.php`**: Invites a family member.
- **GET `/family/list.php`**: Lists family members.
- **GET `/family/notifications.php`**: Gets family notifications.
- **POST `/family/notify_taken.php`**: Creates a family notification.

### Flags & Missing Endpoints
- **Missing Files**: `patients/detail.php`, `patients/update.php`, `medicines/update.php`, `medicines/delete.php`, `schedules/update.php`, `schedules/delete.php`, `voice/upload.php` are called from Flutter but the files do not exist in the provided repository.
- **Missing Endpoints**: No endpoints for Care Notes (`care_notes`) or Escalation Rules (`escalation_rules`). 
- **Security Issues**: 
  - No rate limiting on `verify-otp.php` or `register.php`.
  - `JWT_SECRET` is hardcoded in `api/config/auth.php`.
  - Firebase `firebase_credentials.json` is required but not handled if missing safely.
  - User can be invited to family without an acceptance flow (auto-joined in `invite.php`).

## 4. FLUTTER APP AUDIT
### Found Files
- **Screens**: `login_screen.dart`, `otp_screen.dart`, `register_screen.dart`, `home_screen.dart`, `add_medicine_screen.dart`, `edit_medicine_screen.dart`, `medicines_list_screen.dart`, `medicine_detail_screen.dart`, `alarm_screen.dart`, `family_screen.dart`, `history_screen.dart`, `add_patient_screen.dart`, `patient_profile_screen.dart`, `settings_screen.dart`.
- **Models**: `user_model.dart`, `medicine_model.dart`, `patient_model.dart`, `adherence_log_model.dart`, `family_member_model.dart`.
- **Services**: `api_service.dart`, `alarm_service.dart`, `notification_service.dart`, `voice_cache_service.dart`.
- **Providers**: `auth_provider.dart`, `patient_provider.dart`, `family_provider.dart`.

### Screen Status
- **Auth Flow**: Working (Login -> OTP -> Register). Firebase Auth is integrated.
- **Home Screen**: Working. Displays dashboard and adherence.
- **Medicines List / Add**: Working. Form is comprehensive.
- **Alarm Screen**: Working. Displays pulsing UI and plays voice note.
- **Family / History / Patients / Settings**: Working basic UIs.

### TODO Comments & Hardcoded Values
- **TODOs**: `// Later grab actual FCM token`, `// Need to handle token expiry globally`, `// Auto-resolution (handled in OTP screen generally)`.
- **Hardcoded URLs/Credentials**: `https://aaspaas.yuktaa.com/api` in `api_constants.dart`.

## 5. FEATURE COMPLETION MAP

| Feature | Backend API | Database | Flutter UI | Status |
|---|---|---|---|---|
| User Login | ✅ Done | ✅ Done | ✅ Done | ✅ Done |
| Add Medicine | ✅ Done | ✅ Done | ✅ Done | ✅ Done |
| Set Schedule | ✅ Done | ✅ Done | ✅ Done | ✅ Done |
| Voice Recording | ❌ Missing | ✅ Done | ✅ Done | ⚠️ Partial (Upload API missing) |
| Local Alarm | 🔲 Not Started | 🔲 Not Started | ✅ Done | ✅ Done (Fully Local) |
| Mark as Taken | ✅ Done | ✅ Done | ✅ Done | ✅ Done |
| Family Sharing | ✅ Done | ✅ Done | ✅ Done | ✅ Done |
| Push Notification | ⚠️ Partial | ❌ Missing | ⚠️ Partial | ⚠️ Partial (Missing `family_notifications` table, missing App FCM token setup) |
| History/Tracking | ✅ Done | ✅ Done | ✅ Done | ✅ Done |
| PDF Report | ❌ Missing | 🔲 Not Started | ❌ Missing | ❌ Missing |
| Care Notes | ❌ Missing | ✅ Done | ❌ Missing | ❌ Missing |
| Stock Alert | ✅ Done | ✅ Done | ⚠️ Partial | ⚠️ Partial (UI checks stock but no push notifications sent on low stock) |

## 6. UX & UI AUDIT
- **Screen Ratings**:
  - Auth Flow: Good
  - Home Dashboard: Good
  - Add Medicine: Good
  - Alarm Screen: Good
  - History/Family: Good
- **Missing Elderly-Friendly Design**: Text scaling is not explicitly handled. Fonts are standard size, which may be too small for elderly users. High-contrast themes are absent.
- **Missing Loading/Empty States**: Most are well-handled. `HomeScreen`, `HistoryScreen`, and `MedicinesListScreen` have excellent empty states.
- **Missing Error Handling**: Some API calls silently fail (e.g., in `home_screen.dart` when marking taken, stock decrement ignores errors `catch (_) {}`).
- **Navigation**: Good. 
- **Hardcoded Strings**: No localization. All strings are hardcoded in English, which restricts usability in non-English speaking elderly populations.

## 7. CRITICAL BUGS & RISKS
1. **Crash Risks**: 
   - Trying to access `delete.php`, `update.php` for medicines/schedules will return 404s and crash/throw unhandled exceptions in the app.
   - `AlarmService.scheduleMedicineAlarm` crashes if `DateTime` is in the past, but the logic attempts to bypass this.
2. **Data Loss**: 
   - `ON DELETE CASCADE` is heavily used. Deleting a patient wipes all medicines, schedules, and logs instantly without soft deletion.
3. **API Logic Issues**: 
   - The `family_notifications` table is completely missing from `schema.sql`, meaning `notify_taken.php` and `notifications.php` will throw SQL errors (500 Internal Server Error) in production.
4. **Alarm Logic Issues**: 
   - Alarms are only loaded when `fetchTodayMedicines` is called. If the user doesn't open the app on a given day, recurring alarms might not fire because they are dynamically scheduled based on "today's" doses rather than infinitely repeating.
5. **Security Vulnerabilities**:
   - `api_service.dart` does not handle token expiry (`401`) beyond throwing an exception. The user is not automatically logged out.
   - Anyone can invite any phone number to a family, bypassing user consent.

## 8. WHAT WORKS RIGHT NOW
If you build and run this app today, the end-to-end flow of registering via Firebase OTP, creating a patient profile, adding a medicine, and setting a daily schedule works. When the scheduled time arrives, a local Android alarm will trigger the `AlarmScreen` to pop up with a pulsing animation, allowing the user to mark the medicine as "Taken". Adherence stats update locally. However, advanced features like editing/deleting medicines, uploading voice notes, and family push notifications will fail because the backend files for those specific actions are missing or tables are misconfigured.

## 9. WHAT NEEDS TO BE BUILT NEXT
1. **Most Critical (App won't work without this)**:
   - Add the `family_notifications` table to the database schema.
   - Create the missing PHP files (`medicines/delete.php`, `medicines/update.php`, `schedules/delete.php`, `schedules/update.php`, `voice/upload.php`, `patients/update.php`, `patients/detail.php`).
   - Implement real FCM token registration in Flutter and send it to the backend during login/register so Push Notifications actually work.
2. **Important (Core Features)**:
   - Fix the recurring alarm logic so it schedules for the entire week, not just the current day when the app is opened.
   - Implement Care Notes API and UI.
3. **Nice to Have (Polish)**:
   - Implement PDF Report Generation for doctors.
   - Add localization (e.g., Hindi language support) and dynamic text scaling for elderly users.
   - Add push notifications for Low Stock alerts.

## 10. FILE MAP
### Flutter App (`/aaspaas/lib/`)
- `main.dart`: App entry point and bootloader.
- `core/constants/api_constants.dart`: Stores all API endpoints and base URL.
- `core/theme/app_theme.dart`: Contains global UI theme data.
- `data/api_service.dart`: Core HTTP client with JWT handling and multipart upload.
- `data/models/adherence_log_model.dart`: Model for daily logs.
- `data/models/family_member_model.dart`: Model for family members.
- `data/models/medicine_model.dart`: Model for medicine details.
- `data/models/patient_model.dart`: Model for patient profiles.
- `data/models/user_model.dart`: Model for user data.
- `features/alarm/reminder_alarm_screen.dart`: Legacy/alternate alarm screen.
- `features/auth/login_screen.dart`: Phone number entry for Firebase Auth.
- `features/auth/otp_screen.dart`: OTP verification and JWT exchange.
- `features/auth/register_screen.dart`: Profile completion after OTP.
- `features/family/family_screen.dart`: Lists family members and allows inviting via phone.
- `features/history/history_screen.dart`: Adherence history and statistics view.
- `features/home/home_screen.dart`: Main dashboard displaying today's schedule.
- `features/home/widgets/weekly_chart_widget.dart`: Bar chart for adherence.
- `features/medicines/add_medicine_screen.dart`: Complex form to add medicines and schedules.
- `features/medicines/edit_medicine_screen.dart`: Edit form for existing medicines.
- `features/medicines/medicine_detail_screen.dart`: View medicine details and schedules.
- `features/medicines/medicines_list_screen.dart`: List of all medicines for a patient.
- `features/medicines/screens/alarm_screen.dart`: Full-screen ringing alarm with voice playback.
- `features/medicines/widgets/voice_recorder_widget.dart`: Widget for recording audio.
- `features/patients/add_patient_screen.dart`: Form to create a new patient profile.
- `features/patients/patient_profile_screen.dart`: View and edit patient details.
- `features/settings/settings_screen.dart`: Local SharedPreferences toggles for alarms.
- `services/alarm_service.dart`: AndroidAlarmManager integration.
- `services/notification_service.dart`: FlutterLocalNotifications push/local overlay setup.
- `services/voice_cache_service.dart`: Downloads and caches remote voice files.
- `shared/providers/auth_provider.dart`: State management for authentication.
- `shared/providers/family_provider.dart`: State management for family data.
- `shared/providers/patient_provider.dart`: State management for patients and daily schedules.

### PHP API (`/api/`)
- `auth/register.php`: Registers user and generates JWT.
- `auth/verify-otp.php`: Logs in user, returns JWT.
- `config/auth.php`: JWT generation and validation logic.
- `config/db.php`: Database PDO connection and global error handler.
- `config/fcm.php`: Google OAuth 2.0 FCM v1 push notification sender.
- `family/index.php`: Returns family list with permission checks.
- `family/invite.php`: Adds a user to `family_members`.
- `family/list.php`: Returns family list (duplicate logic of index).
- `family/notifications.php`: Fetches `family_notifications`.
- `family/notify_taken.php`: Creates a `family_notifications` row and sends FCM (implied).
- `helpers/response.php`: JSON formatting wrapper.
- `helpers/upload.php`: File upload handler for voice/images.
- `logs/check_missed.php`: Finds schedules overdue by 10+ minutes.
- `logs/history.php`: Fetches past adherence logs.
- `logs/today.php`: Fetches today's schedules and adherence status.
- `logs/update.php`: Marks a schedule as taken/skipped/snoozed.
- `medicines/add.php`: Inserts new medicine.
- `medicines/decrement_stock.php`: Reduces medicine stock_count by 1.
- `medicines/index.php`: Lists medicines for a patient.
- `patients/create.php`: Inserts a new patient profile.
- `patients/index.php`: Lists patients accessible to the user.
- `schedules/add.php`: Inserts a new schedule for a medicine.
- `schedules/index.php`: Lists schedules for a medicine.

### Database (`/database/`)
- `schema.sql`: Complete MySQL table generation script (missing `family_notifications` table).

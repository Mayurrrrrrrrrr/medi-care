# Fixes Applied

## Task 1: Fix Database
- **`database/schema.sql`**: Added the `family_notifications` table with all foreign keys and constraints at the end of the file. Also added `deleted_at TIMESTAMP NULL DEFAULT NULL` to the `medicines` table to support the required soft delete functionality.

## Task 2: Create Missing PHP Files
- **`api/patients/detail.php`**: Created GET endpoint to return patient details along with medicines and their active schedules. Added JWT authentication and permissions validation via `family_members` and `patient_profiles.created_by_user_id`.
- **`api/patients/update.php`**: Created PUT endpoint to update patient information (`name`, `conditions`, `doctor_name`, `emergency_contact`, `photo_url`).
- **`api/medicines/update.php`**: Created PUT endpoint to handle updates for an existing medicine record.
- **`api/medicines/delete.php`**: Created DELETE endpoint that implements a "soft delete" by setting the `deleted_at` column in the `medicines` table.
- **`api/schedules/update.php`**: Created PUT endpoint to update specific schedule properties (`time_slot`, `days_of_week`, etc).
- **`api/schedules/delete.php`**: Created DELETE endpoint for hard deleting a schedule, which also proactively cleans up pending reminder logs associated with it for the future.
- **`api/voice/upload.php`**: Created POST endpoint using `multipart/form-data` to upload `.m4a` files. It correctly saves them in `/uploads/voice/` mapping to `voice_{schedule_id}_{timestamp}.m4a` and handles database inserts/updates in `voice_reminders`.
- **`api/helpers/upload.php`**: Updated the existing helper to optionally accept a custom filename (`$custom_filename`), which allows the voice upload script to dictate the exact timestamped name.

## Task 3: Fix Alarm Scheduling
- **`aaspaas/lib/data/models/medicine_model.dart`**: Added `daysOfWeek` property to the model so schedules can be correctly mapped by their days.
- **`aaspaas/lib/services/alarm_service.dart`**: 
  - Overhauled alarm scheduling logic. Created `scheduleAllAlarms()` that loops over the provided nested medicines/schedules from the patient detail API.
  - Implemented 7-day lookahead scheduling, calculating MySQL's DAYOFWEEK against Dart's Weekday structure.
  - Generates deterministic alarm IDs (`scheduleId * 10000 + i`) to prevent duplicates.
  - Added `cancelAllAlarms()` to systematically clear scheduled alarms before a fresh batch is programmed.
  - Added `@pragma('vm:entry-point') static Future<void> rescheduleOnAppOpen()` which hits the backend APIs (`patientsIndex` and `patientDetail`) to reconstruct and rebuild alarms dynamically.
- **`aaspaas/lib/main.dart`**: Refactored `Bootloader` into a `StatefulWidget` to execute `AlarmService.rescheduleOnAppOpen()` immediately upon successful background authentication, and registered it with `AndroidAlarmManager.periodic()` for rolling 12-hour background execution.

## Task 4: Wire FCM Token to Backend
- **`aaspaas/lib/shared/providers/auth_provider.dart`**: Added `_setupFCM()` method which grabs the device FCM token via `FirebaseMessaging.instance.getToken()` after successful login. It automatically issues a POST to the backend with this token. It also sets up `onTokenRefresh.listen()` to automatically sync updated FCM tokens.
- **`api/auth/update_fcm.php`**: Created POST endpoint to safely update the `fcm_token` of the authenticated `user_id` inside the `users` table.

## Task 5: Fix Silent Error Handling in Flutter
- **`aaspaas/lib/features/home/home_screen.dart`**: Addressed two critical instances where `catch (_) {}` swallowed errors for auto-decrementing stock and triggering family notifications. Both `catch` blocks now correctly log using `debugPrint("...")` and display a unified red `SnackBar` informing the user with "Could not update. Please try again." if an API call fails locally.

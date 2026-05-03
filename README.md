# Nishchint — निश्चिंत
## Family Medicine Reminder App

### Tagline
"दूर हो, पर चिंता नहीं" — Far away. Never absent.

### About
Nishchint is a specialized medicine reminder application designed to bridge the gap between elderly patients and their family caregivers. Unlike generic reminder apps, Nishchint uses recorded voice messages from family members to provide a personal touch to medical care. It features real-time adherence tracking, stock alerts, and comprehensive doctor reports to ensure your loved ones never miss a dose, no matter how far you are.

### Tech Stack
| Component | Technology |
|---|---|
| Frontend | Flutter (Android/iOS) |
| Backend | PHP 8.x |
| Database | MySQL |
| Notifications | Firebase Cloud Messaging (FCM) |
| Local Notifications | flutter_local_notifications |
| Audio | flutter_sound, audioplayers |

### Project Structure
```
.
├── nishchint/              # Flutter Application source code
│   ├── lib/
│   │   ├── core/           # Constants, Theme, Utils
│   │   ├── data/           # API Services and Models
│   │   ├── features/       # Feature-based modules (Auth, Home, Medicines, etc.)
│   │   ├── services/       # Background services (Alarm, Notification)
│   │   └── shared/         # Common widgets and providers
│   └── assets/             # Images, sounds, and fonts
├── api/                    # PHP Backend source code
│   ├── auth/               # User registration and OTP verification
│   ├── config/             # Database, Auth, and FCM configuration
│   ├── family/             # Caregiver and notification logic
│   ├── helpers/            # Shared response and upload utilities
│   ├── medicines/          # Medicine management and stock tracking
│   ├── notes/              # Care notes management
│   ├── patients/           # Patient profile management
│   ├── reports/            # PDF and data reports generation
│   ├── schedules/          # Medication scheduling logic
│   └── voice/              # Voice recording and playback handling
├── database/               # SQL schema files
└── DEPLOYMENT.md           # Step-by-step server deployment guide
```

### Features
- **Voice Reminders**: Record reminders in your own voice for your family members.
- **Real-time Adherence**: Get notified immediately when a patient takes or skips their medicine.
- **Stock Management**: Track medicine counts and receive "Low Stock" push notifications.
- **Care Notes**: Add important instructions or side-effect logs to specific medicines.
- **Doctor Reports**: Generate professional PDF reports with adherence statistics to share with healthcare providers.
- **Accessibility**: Elderly-friendly UI with Large Text Mode and Hindi localization support.
- **Escalation Rules**: Notify family members if a critical dose is missed for more than 15 minutes.

### Setup — Backend
Refer to [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions on hosting the PHP API and configuring the database.

### Setup — Flutter
1. Ensure you have Flutter installed.
2. Navigate to the `nishchint` directory.
3. Run:
   ```bash
   flutter pub get
   ```
4. Run on a connected device:
   ```bash
   flutter run
   ```

### API Endpoints
| Method | Path | Description |
|---|---|---|
| POST | `/auth/register.php` | User registration |
| POST | `/auth/verify-otp.php` | OTP verification and JWT issuance |
| GET | `/patients/index.php` | List all patient profiles for a user |
| POST | `/patients/create.php` | Create a new patient profile |
| GET | `/medicines/index.php` | List medicines for a specific patient |
| POST | `/medicines/add.php` | Add a new medicine |
| POST | `/medicines/decrement_stock.php`| Decrease medicine count and check alerts |
| GET | `/logs/today.php` | Fetch medication schedule for today |
| POST | `/logs/update.php` | Mark medicine as taken/skipped/snoozed |
| GET | `/reports/doctor_report.php` | Fetch adherence data for PDF report |

### Database Schema
1. **users**: Stores user credentials and FCM tokens.
2. **patient_profiles**: Core profiles for the individuals receiving care.
3. **family_members**: Links users to patients with specific roles (primary/member).
4. **medicines**: Medicine details including stock and criticality.
5. **medicine_schedules**: Time slots and days for each medicine.
6. **voice_reminders**: Links audio files to specific schedules.
7. **reminder_logs**: History of medicine adherence.
8. **escalation_rules**: Configuration for missed dose alerts.
9. **care_notes**: User-added notes for specific medications.
10. **family_notifications**: Record of push notifications sent to family.

### App Screens
- **Login/OTP**: Secure phone-based authentication.
- **Home**: Daily schedule overview and patient switching.
- **Medicines List**: Overview of all medications for a patient.
- **Medicine Detail**: Detailed info, schedules, and care notes.
- **Alarm Screen**: High-priority full-screen reminder with voice playback.
- **History**: Adherence stats and daily log breakdown.
- **Settings**: Theme toggles, profile management, and logout.

### Build for Release
To build a production-ready APK:
```bash
flutter build apk --release
```

### License
This project is licensed under the MIT License.

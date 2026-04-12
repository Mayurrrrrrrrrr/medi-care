-- ==========================================================
-- MediCare Family - Database Schema
-- Set Timezone to IST (+05:30)
-- ==========================================================

SET time_zone = '+05:30';

CREATE DATABASE IF NOT EXISTS medicare_family CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE medicare_family;

-- 1. users
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(15) NOT NULL UNIQUE,
  `fcm_token` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. patient_profiles
CREATE TABLE `patient_profiles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `photo_url` VARCHAR(255) DEFAULT NULL,
  `conditions` TEXT DEFAULT NULL,
  `doctor_name` VARCHAR(100) DEFAULT NULL,
  `emergency_contact` VARCHAR(15) DEFAULT NULL,
  `created_by_user_id` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`created_by_user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. family_members
CREATE TABLE `family_members` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `role` ENUM('primary', 'member') NOT NULL DEFAULT 'member',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`patient_id`) REFERENCES `patient_profiles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  UNIQUE KEY `unique_patient_user` (`patient_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. medicines
CREATE TABLE `medicines` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `form` ENUM('tablet', 'syrup', 'injection', 'capsule') NOT NULL,
  `dose` VARCHAR(50) NOT NULL,
  `color_shape` VARCHAR(100) DEFAULT NULL,
  `food_timing` ENUM('before_food', 'after_food', 'with_food', 'empty_stomach') NOT NULL,
  `is_critical` TINYINT(1) NOT NULL DEFAULT 0,
  `start_date` DATE NOT NULL,
  `end_date` DATE DEFAULT NULL,
  `stock_count` INT NOT NULL DEFAULT 0,
  `stock_alert_at` INT NOT NULL DEFAULT 10,
  `pill_photo_url` VARCHAR(255) DEFAULT NULL,
  `added_by_user_id` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`patient_id`) REFERENCES `patient_profiles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`added_by_user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. medicine_schedules
CREATE TABLE `medicine_schedules` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `medicine_id` BIGINT UNSIGNED NOT NULL,
  `time_slot` TIME NOT NULL,
  `label` VARCHAR(100) DEFAULT NULL,
  `days_of_week` VARCHAR(20) NOT NULL COMMENT 'e.g., 1,2,3,4,5,6,7',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`medicine_id`) REFERENCES `medicines`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. voice_reminders
CREATE TABLE `voice_reminders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id` BIGINT UNSIGNED NOT NULL,
  `recorded_by_user_id` BIGINT UNSIGNED NOT NULL,
  `file_path` VARCHAR(255) NOT NULL,
  `file_url` VARCHAR(255) NOT NULL,
  `message_text` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`schedule_id`) REFERENCES `medicine_schedules`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`recorded_by_user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  UNIQUE KEY `unique_schedule_voice` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. reminder_logs
CREATE TABLE `reminder_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id` BIGINT UNSIGNED NOT NULL,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `scheduled_datetime` DATETIME NOT NULL,
  `status` ENUM('pending', 'taken', 'skipped', 'snoozed') NOT NULL DEFAULT 'pending',
  `updated_by_user_id` BIGINT UNSIGNED DEFAULT NULL,
  `skip_reason` VARCHAR(255) DEFAULT NULL,
  `logged_at` TIMESTAMP ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`schedule_id`) REFERENCES `medicine_schedules`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`patient_id`) REFERENCES `patient_profiles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`updated_by_user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
  UNIQUE KEY `unique_schedule_datetime` (`schedule_id`, `scheduled_datetime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. escalation_rules
CREATE TABLE `escalation_rules` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `escalate_after_minutes` INT NOT NULL DEFAULT 15,
  `notify_user_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`patient_id`) REFERENCES `patient_profiles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`notify_user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. care_notes
CREATE TABLE `care_notes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `medicine_id` BIGINT UNSIGNED NOT NULL,
  `note_text` TEXT NOT NULL,
  `added_by_user_id` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`medicine_id`) REFERENCES `medicines`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`added_by_user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

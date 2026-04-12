-- Family Notifications table for tracking medicine taken confirmations and missed dose alerts
CREATE TABLE IF NOT EXISTS family_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    triggered_by_user_id INT NOT NULL,
    type ENUM('taken_confirmation', 'missed_escalation', 'voice_note') DEFAULT 'taken_confirmation',
    medicine_name VARCHAR(255) NOT NULL,
    message TEXT,
    voice_note_url VARCHAR(500) DEFAULT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

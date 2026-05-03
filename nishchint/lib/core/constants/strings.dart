import '../utils/language_helper.dart';

class AppStrings {
  // Home
  static const String goodMorningEn = "Good Morning";
  static const String goodMorningHi = "सुप्रभात";
  static const String todaysMedicinesEn = "Today's Medicines";
  static const String todaysMedicinesHi = "आज की दवाइयां";
  static const String markTakenEn = "Mark as Taken";
  static const String markTakenHi = "ले ली";
  
  // Alarm screen
  static const String timeForMedicineEn = "Time for your medicine";
  static const String timeForMedicineHi = "दवाई लेने का समय";
  static const String takenEn = "TAKEN";
  static const String takenHi = "ले ली ✓";
  static const String snoozeEn = "SNOOZE 10 min";
  static const String snoozeHi = "10 मिनट बाद";
  static const String skipEn = "SKIP";
  static const String skipHi = "छोड़ें";
  static const String criticalMedicineEn = "Critical Medicine — Do Not Skip";
  static const String criticalMedicineHi = "जरूरी दवाई — मत छोड़ें";
  
  // Food timing
  static const String beforeFoodEn = "Before Food";
  static const String beforeFoodHi = "खाने से पहले";
  static const String afterFoodEn = "After Food";
  static const String afterFoodHi = "खाने के बाद";
  static const String withFoodEn = "With Food";
  static const String withFoodHi = "खाने के साथ";
  static const String emptyStomachEn = "Empty Stomach";
  static const String emptyStomachHi = "खाली पेट";
  
  // Errors
  static const String couldNotUpdateEn = "Could not update. Please try again.";
  static const String couldNotUpdateHi = "अपडेट नहीं हो सका। फिर कोशिश करें।";
  
  // Settings
  static const String largeTextModeEn = "Large Text Mode";
  static const String largeTextModeHi = "बड़े अक्षर";
  static const String languageEn = "Language";
  static const String languageHi = "भाषा";

  static String getFoodTiming(String timing) {
    switch (timing.toLowerCase()) {
      case 'before_food':
        return t(beforeFoodEn, beforeFoodHi);
      case 'after_food':
        return t(afterFoodEn, afterFoodHi);
      case 'with_food':
        return t(withFoodEn, withFoodHi);
      case 'empty_stomach':
        return t(emptyStomachEn, emptyStomachHi);
      default:
        return timing.replaceAll('_', ' ').toUpperCase();
    }
  }
}

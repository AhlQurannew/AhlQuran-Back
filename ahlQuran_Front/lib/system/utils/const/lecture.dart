const List<bool> trueFalse = [true, false];
const List<String> type = ["حفظ ومراجعة", "أخرى"];
const List<String> category = ["male", "female", "both"];

// Map Arabic UI text to English backend values
String getCircleTypeValue(String arabicType) {
  switch (arabicType) {
    case "حفظ ومراجعة":
      return "memorization and revision";
    case "أخرى":
      return "other";
    default:
      return arabicType;
  }
}

// Map English backend values to Arabic UI text
String getCircleTypeText(String? englishType) {
  switch (englishType) {
    case "memorization and revision":
      return "حفظ ومراجعة";
    case "other":
      return "أخرى";
    default:
      return englishType ?? '';
  }
}

int transformBool(bool value) => value ? 1 : 0;

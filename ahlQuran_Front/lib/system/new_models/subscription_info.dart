import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class SubscriptionInfo implements Model {
  dynamic subscriptionId;
  dynamic studentId;
  dynamic enrollmentDate;
  dynamic exitDate;
  dynamic exitReason;
  dynamic isExemptFromPayment;
  dynamic exemptionPercentage;

  SubscriptionInfo({
    this.subscriptionId,
    this.studentId,
    this.enrollmentDate,
    this.exitDate,
    this.exitReason,
    this.isExemptFromPayment,
    this.exemptionPercentage,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      SubscriptionInfo(
        subscriptionId: json['subscriptionId'] ?? json['subscription_id'],
        studentId: json['studentId'] ?? json['student_id'],
        enrollmentDate: json['enrollmentDate'] ?? json['enrollment_date'],
        exitDate: json['exitDate'] ?? json['exit_date'],
        exitReason: json['exitReason'] ?? json['exit_reason'],
        isExemptFromPayment:
            json['isExemptFromPayment'] ?? json['is_exempt_from_payment'],
        exemptionPercentage:
            json['exemptionPercentage'] ?? json['exemption_percentage'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'subscription_id': subscriptionId,
        'student_id': studentId,
        'enrollment_date': enrollmentDate,
        'exit_date': exitDate,
        'exit_reason': exitReason,
        'is_exempt_from_payment': isExemptFromPayment,
        'exemption_percentage': exemptionPercentage,
      };

  @override
  bool get isComplete =>
      subscriptionId != null && studentId != null && enrollmentDate != null;
}

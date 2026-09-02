import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class Appreciation implements Model {
  dynamic appreciationId;
  dynamic pointMin;
  dynamic pointMax;
  dynamic note;

  Appreciation({
    this.appreciationId,
    this.pointMin,
    this.pointMax,
    this.note,
  });

  factory Appreciation.fromJson(Map<String, dynamic> json) => Appreciation(
        appreciationId: json['appreciation_id'],
        pointMin: json['point_min'],
        pointMax: json['point_max'],
        note: json['note'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'appreciation_id': appreciationId,
        'point_min': pointMin,
        'point_max': pointMax,
        'note': note,
      };

  Appreciation copyWith({String? note, int? pointMin, int? pointMax}) {
    return Appreciation(
      note: note ?? this.note,
      pointMin: pointMin ?? this.pointMin,
      pointMax: pointMax ?? this.pointMax,
    );
  }

  @override
  bool get isComplete =>
      appreciationId != null ||
      pointMin != null ||
      pointMax != null ||
      note != null;
}

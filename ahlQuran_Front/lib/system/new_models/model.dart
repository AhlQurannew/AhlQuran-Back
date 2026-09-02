abstract class Model {
  bool get isComplete;

  Map<String, dynamic> toJson();
  factory Model.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError(
        'fromJson method must be implemented in subclasses');
  }
}

import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  @JsonKey(name: "_id", includeIfNull: false)
  final String? id;
  final String title;
  final String description;
  final bool done;
  final bool deleted;

  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.done,
    required this.deleted,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

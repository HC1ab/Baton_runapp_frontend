import 'package:intl/intl.dart';

class NoticeSummaryModel {
  const NoticeSummaryModel({
    required this.noticeId,
    required this.title,
    required this.createdAt,
    required this.isPinned,
  });

  final int noticeId;
  final String title;
  final DateTime createdAt;
  final bool isPinned;

  String get formattedDate => DateFormat('yyyy.MM.dd').format(createdAt);

  factory NoticeSummaryModel.fromJson(Map<String, dynamic> json) =>
      NoticeSummaryModel(
        noticeId: (json['noticeId'] as num).toInt(),
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isPinned: json['isPinned'] as bool? ?? false,
      );
}

class NoticeDetailModel {
  const NoticeDetailModel({
    required this.noticeId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isPinned,
  });

  final int noticeId;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isPinned;

  String get formattedDate => DateFormat('yyyy.MM.dd').format(createdAt);

  factory NoticeDetailModel.fromJson(Map<String, dynamic> json) =>
      NoticeDetailModel(
        noticeId: (json['noticeId'] as num).toInt(),
        title: json['title'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isPinned: json['isPinned'] as bool? ?? false,
      );
}

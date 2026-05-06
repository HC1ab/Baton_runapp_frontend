class ApiResponse<T> {
  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final T data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic rawData) dataParser,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: dataParser(json['data']),
    );
  }
}

class GroupPageResponse {
  GroupPageResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.numberOfElements,
    required this.empty,
  });

  final List<GroupRunningItem> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final int numberOfElements;
  final bool empty;

  factory GroupPageResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawContent =
        json['content'] as List<dynamic>? ?? <dynamic>[];

    return GroupPageResponse(
      content: rawContent
          .map((dynamic e) => GroupRunningItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pageNumber: json['number'] as int? ?? 0,
      pageSize: json['size'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? rawContent.length,
      totalPages: json['totalPages'] as int? ?? 1,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      numberOfElements: json['numberOfElements'] as int? ?? rawContent.length,
      empty: json['empty'] as bool? ?? rawContent.isEmpty,
    );
  }
}

class GroupRunningItem {
  GroupRunningItem({
    required this.groupId,
    required this.title,
    required this.hostNickname,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.startTime,
    required this.status,
    required this.createdAt,
  });

  final int groupId;
  final String title;
  final String hostNickname;
  final int currentParticipants;
  final int maxParticipants;
  final DateTime startTime;
  final String status;
  final DateTime createdAt;

  factory GroupRunningItem.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    return GroupRunningItem(
      groupId: json['groupId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      hostNickname: json['hostNickname'] as String? ?? '',
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      maxParticipants: json['maxParticipants'] as int? ?? 0,
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? now,
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
    );
  }
}
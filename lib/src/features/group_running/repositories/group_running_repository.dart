import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../models/group_running_models.dart';

class GroupRunningRepository {
  GroupRunningRepository({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<GroupPageResponse> fetchGroupRunningList() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/groups');
      final Map<String, dynamic> payload = response.data as Map<String, dynamic>;

      final ApiResponse<GroupPageResponse> parsed = ApiResponse<GroupPageResponse>.fromJson(
        payload,
        (dynamic rawData) => GroupPageResponse.fromJson(rawData as Map<String, dynamic>),
      );

      return parsed.data;
    } on DioException {
      // Keep the social tab usable during early frontend development.
      return GroupPageResponse(
        content: <GroupRunningItem>[
          GroupRunningItem(
            groupId: 1,
            title: '구서동 러닝 뛸 사람',
            hostNickname: 'ProteinSu',
            currentParticipants: 1,
            maxParticipants: 4,
            startTime: DateTime(2026, 3, 27, 16),
            status: 'RECRUITING',
            createdAt: DateTime(2026, 3, 29, 17, 2, 21),
          ),
          GroupRunningItem(
            groupId: 2,
            title: '금정천 5K 저녁 러닝',
            hostNickname: 'JinRunner',
            currentParticipants: 3,
            maxParticipants: 6,
            startTime: DateTime(2026, 5, 5, 19, 30),
            status: 'RECRUITING',
            createdAt: DateTime(2026, 5, 4, 20, 10),
          ),
          GroupRunningItem(
            groupId: 3,
            title: '센텀 브릿지 템포런',
            hostNickname: 'MinaPace',
            currentParticipants: 5,
            maxParticipants: 8,
            startTime: DateTime(2026, 5, 6, 6, 40),
            status: 'RECRUITING',
            createdAt: DateTime(2026, 5, 4, 20, 20),
          ),
          GroupRunningItem(
            groupId: 4,
            title: '주말 롱런 12K 크루',
            hostNickname: 'BlueTrack',
            currentParticipants: 7,
            maxParticipants: 10,
            startTime: DateTime(2026, 5, 9, 8, 0),
            status: 'RECRUITING',
            createdAt: DateTime(2026, 5, 4, 20, 30),
          ),
        ],
        pageNumber: 0,
        pageSize: 5,
        totalElements: 4,
        totalPages: 1,
        first: true,
        last: true,
        numberOfElements: 4,
        empty: false,
      );
    }
  }
}
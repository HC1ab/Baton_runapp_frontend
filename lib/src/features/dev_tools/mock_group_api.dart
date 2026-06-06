import 'package:dio/dio.dart';

import '../social/data/group_api.dart';

class MockGroupApi extends GroupApi {
  MockGroupApi() : super(Dio());

  @override
  Future<int> create({
    required String title,
    required String content,
    required int maxParticipants,
    required String startTimeIsoLocal,
    required String endTimeIsoLocal,
    required int distanceKm,
    required String location,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return 1;
  }

  @override
  Future<void> join({required int groupId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> delete({required int groupId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> update({required int groupId, int? maxParticipants}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<List<Map<String, dynamic>>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [];
  }

  @override
  Future<void> leave({required int groupId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
}

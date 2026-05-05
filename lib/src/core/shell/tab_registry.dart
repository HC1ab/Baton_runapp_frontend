import 'package:flutter/material.dart';

/// 탭 하나를 표현하는 불변 모델.
/// [builder]는 IndexedStack이 처음 렌더링할 때 호출됨.
class TabEntry {
  const TabEntry({required this.builder});

  final WidgetBuilder builder;
}

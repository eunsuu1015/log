// 기록 단일 행 위젯. 캘린더·타임라인 두 화면에서 공통으로 사용한다.
// 기분 동그라미 + 기분 텍스트 (왼쪽), 시간 (오른쪽) 구성.
// 구분선은 각 부모 위젯(ListView.separated / ListView.builder)이 처리한다.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

/// 기록 단일 행. 캘린더·타임라인 공용 위젯.
class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;

  const EntryCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

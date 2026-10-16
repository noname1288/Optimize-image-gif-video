import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/category_model.dart';

class HomeLocalDataSource {
  static const _path = 'assets/mock/home_recommends.json';

  Future<List<CategoryModel>> fetchCategories() async {
    var raw = await rootBundle.loadString(_path);
    if (raw.startsWith('﻿')) raw = raw.substring(1); // strip BOM
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list =
        (json['data'] as Map<String, dynamic>)['category_list'] as List;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

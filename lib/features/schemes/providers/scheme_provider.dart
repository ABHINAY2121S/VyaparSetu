import 'package:flutter/material.dart';
import '../../../shared/models/scheme_model.dart';

class SchemeProvider extends ChangeNotifier {
  List<SchemeModel> _schemes = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  List<SchemeModel> get schemes => _filteredSchemes;
  List<SchemeModel> get allSchemes => _schemes;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = {'All', ..._schemes.map((s) => s.category)};
    return cats.toList();
  }

  List<SchemeModel> get _filteredSchemes {
    if (_selectedCategory == 'All') return _schemes;
    return _schemes
        .where((s) => s.category == _selectedCategory)
        .toList();
  }

  Future<void> load({required double loanReadinessScore}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _schemes = SchemeModel.allSchemes;

    // Sort by eligibility (highest first)
    _schemes.sort((a, b) => b.eligibilityPercent.compareTo(a.eligibilityPercent));

    _isLoading = false;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<SchemeModel> get topSchemes => _schemes.take(3).toList();
}

class InsightsProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _monthlyData = [];
  final bool _isLoading = false;

  List<Map<String, dynamic>> get monthlyData => _monthlyData;
  bool get isLoading => _isLoading;
}

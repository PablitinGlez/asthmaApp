import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../domain/measurements/entities/measurement_history_item.dart';
import '../../auth/providers/auth_provider.dart';

class RiskAlertNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void trigger(int pef) => state = pef;
  void clear() => state = null;
}

final riskAlertProvider = NotifierProvider<RiskAlertNotifier, int?>(
  RiskAlertNotifier.new,
);

class MeasurementsState {
  final List<MeasurementHistoryItem> allItems;
  final int currentPage;
  final int pageSize;
  final bool isLoadingMore;

  MeasurementsState({
    required this.allItems,
    this.currentPage = 1,
    this.pageSize = 10,
    this.isLoadingMore = false,
  });

  MeasurementsState copyWith({
    List<MeasurementHistoryItem>? allItems,
    int? currentPage,
    int? pageSize,
    bool? isLoadingMore,
  }) {
    return MeasurementsState(
      allItems: allItems ?? this.allItems,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  List<MeasurementHistoryItem> get visibleItems {
    if (allItems.isEmpty) return [];
    int start = (currentPage - 1) * pageSize;
    int end = start + pageSize;
    if (start >= allItems.length) return [];
    return allItems.sublist(start, end.clamp(0, allItems.length));
  }

  int get totalPages => (allItems.length / pageSize).ceil();
  bool get hasNext => currentPage < totalPages;
  bool get hasPrevious => currentPage > 1;
  bool get hasMore => hasNext;

  bool get isEmpty => allItems.isEmpty;
  bool get isNotEmpty => allItems.isNotEmpty;
  int get length => allItems.length;
  MeasurementHistoryItem operator [](int index) => allItems[index];

  MeasurementHistoryItem get first => allItems.first;
  MeasurementHistoryItem? get firstOrNull =>
      allItems.isEmpty ? null : allItems.first;

  Iterable<T> map<T>(T Function(MeasurementHistoryItem) f) => allItems.map(f);
  Iterable<MeasurementHistoryItem> where(
    bool Function(MeasurementHistoryItem) test,
  ) => allItems.where(test);
  MeasurementHistoryItem firstWhere(
    bool Function(MeasurementHistoryItem) test, {
    MeasurementHistoryItem Function()? orElse,
  }) => allItems.firstWhere(test, orElse: orElse);
  bool any(bool Function(MeasurementHistoryItem) test) => allItems.any(test);
}

class MeasurementsNotifier extends AsyncNotifier<MeasurementsState> {
  @override
  FutureOr<MeasurementsState> build() async {
    final allItems = await _fetchHistory();
    return MeasurementsState(allItems: allItems);
  }

  Future<List<MeasurementHistoryItem>> _fetchHistory() async {
    final dio = ref.read(dioClientProvider);
    final supabaseDs = ref.read(supabaseAuthDataSourceProvider);
    final token = await supabaseDs.getIdToken();

    if (token == null) throw Exception('No auth token');

    final response = await dio.get(
      '/api/measurements/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List<dynamic> data = response.data;
    return data.map((json) => MeasurementHistoryItem.fromJson(json)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final allItems = await _fetchHistory();
      return MeasurementsState(allItems: allItems);
    });
  }

  Future<void> goToPage(int page) async {
    final current = state.value;
    if (current == null || page < 1 || page > current.totalPages) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, currentPage: page));

    await Future.delayed(const Duration(milliseconds: 300));

    state = AsyncData(
      current.copyWith(isLoadingMore: false, currentPage: page),
    );
  }

  Future<void> loadMore() => nextPage();

  Future<void> nextPage() async {
    final current = state.value;
    if (current == null || !current.hasNext) return;
    await goToPage(current.currentPage + 1);
  }

  Future<void> previousPage() async {
    final current = state.value;
    if (current == null || !current.hasPrevious) return;
    await goToPage(current.currentPage - 1);
  }

  Future<void> silentRefresh({bool checkRisk = false}) async {
    final previous = state.value;
    try {
      final freshItems = await _fetchHistory();
      state = AsyncData(
        MeasurementsState(
          allItems: freshItems,
          currentPage: previous?.currentPage ?? 1,
          pageSize: previous?.pageSize ?? 10,
        ),
      );

      if (checkRisk && freshItems.isNotEmpty) {
        final latestPef = freshItems.first.pef;
        if (latestPef != null && latestPef < 350) {
          final previousPef = previous?.allItems.firstOrNull?.pef;
          if (latestPef != previousPef) {
            ref.read(riskAlertProvider.notifier).trigger(latestPef);
          }
        }
      }
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
    }
  }
}

final measurementsProvider =
    AsyncNotifierProvider<MeasurementsNotifier, MeasurementsState>(
      MeasurementsNotifier.new,
    );

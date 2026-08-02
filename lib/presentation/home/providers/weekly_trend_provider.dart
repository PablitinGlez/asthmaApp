import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import './measurements_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../domain/models/weekly_trend.dart';

class WeeklyTrendState {
  final WeeklyTrendResponse? data;
  final bool isLoading;
  final String? errorMessage;

  WeeklyTrendState({this.data, this.isLoading = false, this.errorMessage});

  WeeklyTrendState copyWith({
    WeeklyTrendResponse? data,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WeeklyTrendState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WeeklyTrendNotifier extends Notifier<WeeklyTrendState> {
  WebSocketChannel? _channel;

  @override
  WeeklyTrendState build() {
    
    
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      Future.microtask(() => _initWebSocket(user.dbId));
    } else {
      
      Future.delayed(const Duration(seconds: 3), () {
        final u = ref.read(authStateProvider).value;
        if (u != null && _channel == null) _initWebSocket(u.dbId);
      });
    }

    Future.microtask(() => fetchWeeklyTrend());

    ref.onDispose(() {
      _channel?.sink.close();
    });

    return WeeklyTrendState(isLoading: true);
  }

  void _initWebSocket(int userId) {
    if (_channel != null) return; 

    try {
      final dioClient = ref.read(dioClientProvider);
      final baseUrl = dioClient.baseUrl;
      final wsUrl = baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/api/measurements/ws/trend/$userId');

      _channel = WebSocketChannel.connect(uri);
      print(' WebSocket: Conectado para user $userId');

      _channel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['event'] == 'NEW_MEASUREMENT_READY') {
              fetchWeeklyTrend(isSilentRefresh: true);
              ref
                  .read(measurementsProvider.notifier)
                  .silentRefresh(checkRisk: true);
            }
          } catch (_) {}
        },
        onError: (_) {
          print(' WebSocket: Error — reconectando en 5s...');
          _channel = null;
          
          Future.delayed(const Duration(seconds: 5), () {
            if (state.data != null) _initWebSocket(userId);
          });
        },
        onDone: () {
          print(' WebSocket: Canal cerrado — reconectando en 5s...');
          _channel = null;
          Future.delayed(const Duration(seconds: 5), () {
            if (state.data != null) _initWebSocket(userId);
          });
        },
      );
    } catch (_) {
      _channel = null;
    }
  }

  Future<void> fetchWeeklyTrend({bool isSilentRefresh = false}) async {
    if (!isSilentRefresh) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final user = ref.read(authStateProvider).value;

      final token = await supabaseAuthDS.getIdToken();
      if (token == null || user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No autenticado',
        );
        return;
      }

      final response = await dioClient.get(
        '/api/measurements/weekly-trend',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final trendData = WeeklyTrendResponse.fromJson(response.data);
        state = state.copyWith(data: trendData, isLoading: false);

        
        _initWebSocket(user.dbId);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Error HTTP');
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data['detail'] ?? 'Error de conexión',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: \$e',
      );
    }
  }
}

final weeklyTrendProvider =
    NotifierProvider<WeeklyTrendNotifier, WeeklyTrendState>(
      WeeklyTrendNotifier.new,
    );

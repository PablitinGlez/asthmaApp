import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../infrastructure/models/action_plan_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final actionPlanProvider =
    NotifierProvider<ActionPlanNotifier, ActionPlanState>(() {
      return ActionPlanNotifier();
    });

class ActionPlanState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final bool hasPlan;
  final List<ActionStepModel>? steps;

  ActionPlanState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.hasPlan = false,
    this.steps,
  });

  ActionPlanState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? hasPlan,
    List<ActionStepModel>? steps,
  }) {
    return ActionPlanState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      hasPlan: hasPlan ?? this.hasPlan,
      steps: steps ?? this.steps,
    );
  }
}

class ActionPlanNotifier extends Notifier<ActionPlanState> {
  static const _planCacheKey = 'has_medical_plan_cache';

  @override
  ActionPlanState build() {
    final userId = ref.watch(authStateProvider.select((v) => v.value?.id));

    if (userId == null) {
      _saveToCache(false);
      return ActionPlanState(isLoading: false, hasPlan: false);
    }

    _loadFromCache();

    Future.microtask(() => loadActionPlan(isSilent: true));

    return ActionPlanState(isLoading: false);
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPlan = prefs.getBool(_planCacheKey) ?? false;
      if (hasPlan) {
        state = state.copyWith(hasPlan: true);
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(bool hasPlan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_planCacheKey, hasPlan);
    } catch (_) {}
  }

  void resetState() {
    state = state.copyWith(isSuccess: false, errorMessage: null);
  }

  Future<void> loadActionPlan({bool isSilent = false}) async {
    if (!isSilent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);

      final token = await supabaseAuthDS.getIdToken();
      if (token == null) return;

      final response = await dioClient.get(
        '/api/action-plans/steps',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final loadedSteps = data
            .map(
              (json) => ActionStepModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        await _saveToCache(true);
        state = state.copyWith(
          isLoading: false,
          hasPlan: true,
          steps: loadedSteps,
        );
      } else {
        await _saveToCache(false);
        state = state.copyWith(isLoading: false, hasPlan: false);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print('ℹ ActionPlanNotifier: User does not have an action plan yet (Expected 404).');
        await _saveToCache(false);
        state = state.copyWith(isLoading: false, hasPlan: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: isSilent ? null : 'No se pudo cargar el plan médico.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: isSilent ? null : 'Error inesperado al cargar.',
      );
    }
  }

  Future<void> saveActionPlan(String green, String yellow, String red) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);

      final token = await supabaseAuthDS.getIdToken();
      if (token == null) throw Exception('No hay token válido');

      final requestModel = ActionPlanRequestModel(
        planName: "Plan de Acción Médico",
        steps: [
          ActionStepModel(
            stepOrder: 1,
            stepTitle: "Zona Verde",
            stepDescription: green,
            isCritical: false,
          ),
          ActionStepModel(
            stepOrder: 2,
            stepTitle: "Zona Amarilla",
            stepDescription: yellow,
            isCritical: false,
          ),
          ActionStepModel(
            stepOrder: 3,
            stepTitle: "Zona Roja",
            stepDescription: red,
            isCritical: true,
          ),
        ],
      );

      final response = await dioClient.post(
        '/api/action-plans',
        data: requestModel.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          hasPlan: true,
        );
        await loadActionPlan();
      } else {
        throw Exception('Error al guardar el plan');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 &&
          e.response?.data['detail'] == 'Usuario ya tiene un plan activo') {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Ya tienes un plan médico. Próximamente habilitaremos la opción de editarlo.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.response?.data['detail'] ?? 'Error de conexión',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrió un error inesperado',
      );
    }
  }
}

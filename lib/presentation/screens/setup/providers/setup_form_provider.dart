import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetupFormState {
  final String? gender;
  final int? age;
  final double? heightCm;
  final int? personalBestPef;
  final bool isPosting;

  SetupFormState({
    this.gender,
    this.age,
    this.heightCm,
    this.personalBestPef,
    this.isPosting = false,
  });

  SetupFormState copyWith({
    String? gender,
    int? age,
    double? heightCm,
    int? personalBestPef,
    bool? isPosting,
  }) {
    return SetupFormState(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      personalBestPef: personalBestPef ?? this.personalBestPef,
      isPosting: isPosting ?? this.isPosting,
    );
  }

  // Convertimos a JSON para enviar por dio exclude nulls (como lo hace pydantic)
  Map<String, dynamic> toJson() {
    return {
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (heightCm != null) 'height_cm': heightCm,
      if (personalBestPef != null) 'personal_best_pef': personalBestPef,
    };
  }
}

class SetupFormNotifier extends Notifier<SetupFormState> {
  @override
  SetupFormState build() {
    return SetupFormState();
  }

  void setBiometria({
    required String gender,
    required int age,
    required double heightCm,
  }) {
    state = state.copyWith(gender: gender, age: age, heightCm: heightCm);
  }

  void setHistorial({required int pef}) {
    state = state.copyWith(personalBestPef: pef);
  }

  void setPosting(bool value) {
    state = state.copyWith(isPosting: value);
  }
}

final setupFormProvider = NotifierProvider<SetupFormNotifier, SetupFormState>(
  () {
    return SetupFormNotifier();
  },
);

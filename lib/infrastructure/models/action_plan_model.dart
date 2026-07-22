class ActionStepModel {
  final int stepOrder;
  final String stepTitle;
  final String stepDescription;
  final bool isCritical;

  ActionStepModel({
    required this.stepOrder,
    required this.stepTitle,
    required this.stepDescription,
    this.isCritical = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'step_order': stepOrder,
      'step_title': stepTitle,
      'step_description': stepDescription,
      'is_critical': isCritical,
    };
  }

  factory ActionStepModel.fromJson(Map<String, dynamic> json) {
    return ActionStepModel(
      stepOrder: json['step_order'] ?? 0,
      stepTitle: json['step_title'] ?? '',
      stepDescription: json['step_description'] ?? '',
      isCritical: json['is_critical'] ?? false,
    );
  }
}

class ActionPlanRequestModel {
  final String planName;
  final List<ActionStepModel> steps;

  ActionPlanRequestModel({
    this.planName = "Plan de Emergencia",
    required this.steps,
  });

  Map<String, dynamic> toJson() {
    return {
      'plan_name': planName,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }
}

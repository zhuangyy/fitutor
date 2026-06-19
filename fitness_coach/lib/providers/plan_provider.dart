import 'package:flutter/material.dart';
import 'package:fitness_coach/database/plan_dao.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

class PlanProvider extends ChangeNotifier {
  final PlanDao _planDao = PlanDao();
  List<TrainingPlan> _plans = [];
  bool _loading = false;

  List<TrainingPlan> get plans => _plans;
  bool get loading => _loading;

  Future<void> loadPlans() async {
    _loading = true;
    notifyListeners();
    _plans = await _planDao.getAllPlans();
    _loading = false;
    notifyListeners();
  }

  Future<TrainingPlan?> getPlan(int id) async {
    return await _planDao.getPlanById(id);
  }

  Future<int> createPlan(TrainingPlan plan) async {
    final now = DateTime.now().toIso8601String();
    final planToSave = plan.copyWith(createdAt: now, updatedAt: now);
    final id = await _planDao.insertPlan(planToSave);
    await loadPlans();
    return id;
  }

  Future<void> updatePlan(TrainingPlan plan) async {
    plan.updatedAt = DateTime.now().toIso8601String();
    await _planDao.updatePlan(plan);
    await loadPlans();
  }

  Future<void> deletePlan(int id) async {
    await _planDao.deletePlan(id);
    await loadPlans();
  }

  Future<void> savePlanExercises(
      int planId, List<PlanExercise> exercises) async {
    await _planDao.replacePlanExercises(planId, exercises);
    final plan = await _planDao.getPlanById(planId);
    if (plan != null) {
      plan.updatedAt = DateTime.now().toIso8601String();
      await _planDao.updatePlan(plan);
    }
    await loadPlans();
  }

  Future<void> reorderPlans(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final plan = _plans.removeAt(oldIndex);
    _plans.insert(newIndex, plan);
    for (int i = 0; i < _plans.length; i++) {
      if (_plans[i].sortOrder != i) {
        _plans[i] = _plans[i].copyWith(sortOrder: i);
        _plans[i].updatedAt = DateTime.now().toIso8601String();
        await _planDao.updatePlan(_plans[i]);
      }
    }
    notifyListeners();
  }
}

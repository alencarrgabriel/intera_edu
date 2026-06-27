import 'package:flutter/foundation.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/discipline_group.dart';

class GroupsNotifier extends ChangeNotifier {
  List<DisciplineGroup> myGroups = [];
  List<DisciplineGroup> explore = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      myGroups = await sl.groupsRepo.listGroups(mine: true);
      explore = await sl.groupsRepo.listGroups();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> join(String id) async {
    await sl.groupsRepo.joinGroup(id);
    await load();
  }

  Future<void> leave(String id) async {
    await sl.groupsRepo.leaveGroup(id);
    await load();
  }
}

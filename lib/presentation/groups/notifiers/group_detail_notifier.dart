import 'package:flutter/foundation.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/groups_repository.dart';
import '../../../domain/entities/discipline_group.dart';
import '../../../domain/entities/material.dart';
import '../../../domain/entities/post.dart';

class GroupDetailNotifier extends ChangeNotifier {
  DisciplineGroup? group;
  List<Post> feed = [];
  List<GroupMaterial> materials = [];
  List<GroupMember> members = [];
  bool loadingFeed = false;
  bool loadingMaterials = false;
  bool loadingMembers = false;
  String? error;

  Future<void> load(String groupId) async {
    loadingFeed = true;
    loadingMaterials = true;
    loadingMembers = true;
    error = null;
    notifyListeners();
    try {
      group = await sl.groupsRepo.getGroup(groupId);
      feed = await sl.groupsRepo.groupFeed(groupId);
      materials = await sl.materialsRepo.list(groupId);
      members = await sl.groupsRepo.listMembers(groupId);
    } catch (e) {
      error = e.toString();
    }
    loadingFeed = false;
    loadingMaterials = false;
    loadingMembers = false;
    notifyListeners();
  }

  Future<void> reloadFeed() async {
    final g = group;
    if (g == null) return;
    loadingFeed = true;
    notifyListeners();
    feed = await sl.groupsRepo.groupFeed(g.id);
    loadingFeed = false;
    notifyListeners();
  }

  Future<void> reloadMaterials() async {
    final g = group;
    if (g == null) return;
    loadingMaterials = true;
    notifyListeners();
    materials = await sl.materialsRepo.list(g.id);
    loadingMaterials = false;
    notifyListeners();
  }
}

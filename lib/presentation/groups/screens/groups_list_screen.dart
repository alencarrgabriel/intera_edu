import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../notifiers/groups_notifier.dart';
import '../../../domain/entities/discipline_group.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsNotifier>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        backgroundColor: AppTokens.background,
        elevation: 0,
        title: const Text('Grupos de Disciplina',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Consumer<GroupsNotifier>(
        builder: (_, n, __) {
          if (n.loading && n.myGroups.isEmpty && n.explore.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: n.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (n.myGroups.isNotEmpty) ...[
                  _section('Meus grupos'),
                  ...n.myGroups.map(_card),
                  const SizedBox(height: 24),
                ],
                _section('Explorar'),
                if (n.explore.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nenhum grupo ainda. Crie o primeiro!',
                      style: TextStyle(color: AppTokens.onSurfaceVariant),
                    ),
                  )
                else
                  ...n.explore.map(_card),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6)),
      );

  Widget _card(DisciplineGroup g) {
    return Card(
      color: AppTokens.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: AppTokens.outlineVariant, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppTokens.primaryContainer,
          child: Icon(Icons.group_outlined,
              color: AppTokens.onPrimaryContainer, size: 22),
        ),
        title: Text(g.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(
          '${g.memberCount} membros · ${g.postCount} posts · ${g.materialCount} materiais',
          style:
              TextStyle(color: AppTokens.onSurfaceVariant, fontSize: 12.5),
        ),
        trailing: g.isMember
            ? Chip(
                label: const Text('Membro',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                visualDensity: VisualDensity.compact,
                backgroundColor: AppTokens.primaryContainer,
                side: BorderSide.none,
              )
            : null,
        onTap: () => context.push(AppRoutes.groupDetail(g.id)),
      ),
    );
  }
}

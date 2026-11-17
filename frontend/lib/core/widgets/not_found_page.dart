import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import 'empty_state.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Sayfa bulunamadı',
        message: location,
        action: FilledButton(onPressed: () => context.go(AppRoutes.home), child: const Text('Ana sayfaya dön')),
      ),
    );
  }
}

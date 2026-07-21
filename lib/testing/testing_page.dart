import 'package:flutter/material.dart';
import '../testing/sync_testing_widget.dart';

/// Página simplificada para acceder a testing
class TestingPage extends StatelessWidget {
  const TestingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyncTestingWidget();
  }
}

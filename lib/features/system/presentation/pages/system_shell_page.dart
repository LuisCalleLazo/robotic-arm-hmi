import 'package:flutter/material.dart';

import '../../../dashboard/presentation/pages/dashboard_page.dart';
import 'history_page.dart';
import 'machine_creation_page.dart';
import 'process_programming_page.dart';

class SystemShellPage extends StatefulWidget {
  const SystemShellPage({super.key});

  @override
  State<SystemShellPage> createState() => _SystemShellPageState();
}

class _SystemShellPageState extends State<SystemShellPage> {
  int _index = 0;

  static const _items = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Sistema',
    ),
    NavigationDestination(
      icon: Icon(Icons.precision_manufacturing_outlined),
      selectedIcon: Icon(Icons.precision_manufacturing),
      label: 'Máquinas',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_tree_outlined),
      selectedIcon: Icon(Icons.account_tree),
      label: 'Procesos',
    ),
    NavigationDestination(icon: Icon(Icons.history), label: 'Históricos'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: const [
        DashboardPage(),
        MachineCreationPage(),
        ProcessProgrammingPage(),
        HistoryPage(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      destinations: _items,
      onDestinationSelected: (index) => setState(() => _index = index),
    ),
  );
}

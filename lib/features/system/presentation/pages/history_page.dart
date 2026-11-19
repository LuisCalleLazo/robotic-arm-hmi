import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/process.dart';
import '../../domain/entities/process_historic.dart';
import '../../domain/repositories/system_history_repository.dart';
import '../../domain/repositories/system_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Process> _processes = const [];
  final _history = <int, List<ProcessHistoric>>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _processes = await GetIt.I<SystemRepository>().getProcesses();
      final repository = GetIt.I<SystemHistoryRepository>();
      for (final process in _processes) {
        _history[process.id] = await repository.getProcessHistorics(process.id);
      }
    } catch (_) {
      // El histórico es persistencia del maestro; un esclavo solo observa.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_processes.isEmpty) {
      return const Center(child: Text('No hay históricos disponibles.'));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Históricos', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Los registros se generan durante la ejecución de procesos.',
        ),
        const SizedBox(height: 16),
        for (final process in _processes)
          ExpansionTile(
            title: Text(process.name),
            subtitle: Text('${_history[process.id]?.length ?? 0} ejecuciones'),
            children: [
              for (final item in _history[process.id] ?? const [])
                ListTile(
                  leading: Icon(
                    item.finishProcess
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: item.finishProcess ? Colors.green : Colors.orange,
                  ),
                  title: Text(item.startTime.toLocal().toString()),
                  subtitle: Text(
                    item.endTime == null
                        ? 'En curso'
                        : 'Finalizó: ${item.endTime!.toLocal()}',
                  ),
                ),
              if ((_history[process.id] ?? const []).isEmpty)
                const ListTile(title: Text('Sin ejecuciones registradas.')),
            ],
          ),
      ],
    );
  }
}

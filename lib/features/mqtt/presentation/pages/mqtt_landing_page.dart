import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../data/mqtt_connection_service.dart';
import '../../domain/entities/mqtt_connection_state.dart';

class MqttLandingPage extends StatelessWidget {
  const MqttLandingPage({required this.service, super.key});

  final MqttConnectionService service;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: StreamBuilder<BrokerConnectionState>(
              stream: service.states,
              initialData: service.state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? service.state;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Conexión MQTT',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.isConnected
                          ? 'Conectado a ${state.host}:${state.port}'
                          : 'Conéctate al broker para abrir el sistema.',
                      textAlign: TextAlign.center,
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: state.status == MqttConnectionStatus.connecting
                          ? null
                          : () => showMqttConnectionDialog(context, service),
                      icon: state.status == MqttConnectionStatus.connecting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi),
                      label: Text(
                        state.isConnected
                            ? 'Cambiar broker'
                            : 'Conectar a MQTT',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> showMqttConnectionDialog(
  BuildContext context,
  MqttConnectionService service,
) => showDialog<void>(
  context: context,
  builder: (_) => _MqttConnectionDialog(service: service),
);

class _MqttConnectionDialog extends StatefulWidget {
  const _MqttConnectionDialog({required this.service});

  final MqttConnectionService service;

  @override
  State<_MqttConnectionDialog> createState() => _MqttConnectionDialogState();
}

class _MqttConnectionDialogState extends State<_MqttConnectionDialog> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;
  bool _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = widget.service.state;
    _host = TextEditingController(text: current.host ?? '');
    _port = TextEditingController(
      text: '${current.port ?? (kIsWeb ? 9001 : 1883)}',
    );
    _username = TextEditingController();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final port = int.tryParse(_port.text.trim());
    if (port == null) {
      setState(() => _error = 'El puerto debe ser un número.');
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await widget.service.connect(
        host: _host.text,
        port: port,
        username: _username.text,
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Conectar al broker MQTT'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _host,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'IP o host del broker',
              hintText: '192.168.1.100',
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _connect(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            decoration: InputDecoration(
              labelText: kIsWeb ? 'Puerto MQTT sobre WebSocket' : 'Puerto MQTT',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            decoration: const InputDecoration(labelText: 'Usuario (opcional)'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            decoration: const InputDecoration(
              labelText: 'Contraseña (opcional)',
            ),
            obscureText: true,
            onSubmitted: (_) => _connect(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _connecting ? null : _connect,
              icon: _connecting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(_connecting ? 'Conectando…' : 'Conectar'),
            ),
          ),
        ],
      ),
    ),
    actions: [
      if (widget.service.state.isConnected)
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await widget.service.disconnect();
            if (mounted) navigator.pop();
          },
          child: const Text('Desconectar'),
        ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
    ],
  );
}

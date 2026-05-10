import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';

class IpSetupScreen extends ConsumerStatefulWidget {
  const IpSetupScreen({super.key});

  @override
  ConsumerState<IpSetupScreen> createState() => _IpSetupScreenState();
}

class _IpSetupScreenState extends ConsumerState<IpSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  bool _loading = false;

  static final _ipv4Regex = RegExp(
    r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
  );

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an IP address';
    final match = _ipv4Regex.firstMatch(value.trim());
    if (match == null) return 'Enter a valid IPv4 address (e.g. 192.168.1.42)';
    for (var i = 1; i <= 4; i++) {
      if (int.parse(match.group(i)!) > 255) {
        return 'Each octet must be 0–255';
      }
    }
    return null;
  }

  Future<void> _onConnect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ip = _ipController.text.trim();
    await ref.read(espIpRepositoryProvider).saveIp(ip);
    ref.read(espIpProvider.notifier).state = ip;
    // app.dart watches espIpProvider — it will swap to MainScaffold automatically
  }

  Future<void> _onUseMock() async {
    await ref.read(espIpRepositoryProvider).clearIp();
    ref.read(espIpProvider.notifier).state = '__mock__';
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_find_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connect to ESP32',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the IP address shown in the\nESP32 serial monitor.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _ipController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'ESP32 IP Address',
                      hintText: '192.168.1.42',
                      prefixIcon: const Icon(Icons.router_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _validateIp,
                    onFieldSubmitted: (_) => _onConnect(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _onConnect,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.link_rounded),
                      label: const Text('Connect'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loading ? null : _onUseMock,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Use Mock Data instead'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

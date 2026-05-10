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
  // ESP32 AP mode always assigns itself 192.168.4.1
  final _ipController = TextEditingController(text: '192.168.4.1');
  bool _loading = false;

  static final _ipv4Regex = RegExp(
    r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
  );

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an IP address';
    final match = _ipv4Regex.firstMatch(value.trim());
    if (match == null) return 'Enter a valid IPv4 address (e.g. 192.168.4.1)';
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
                    'First connect your phone to the ESP32 Wi-Fi,\nthen tap Connect.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  // AP credentials hint card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.wifi_rounded,
                              size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 6),
                          Text('ESP32 Access Point',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700)),
                        ]),
                        const SizedBox(height: 6),
                        _ApRow('SSID', 'SmartIrrigation'),
                        _ApRow('Password', '12345678'),
                        _ApRow('IP', '192.168.4.1'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _ipController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'ESP32 IP Address',
                      hintText: '192.168.4.1',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApRow extends StatelessWidget {
  final String label;
  final String value;
  const _ApRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black45)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }
}

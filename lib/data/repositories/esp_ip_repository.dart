import 'package:shared_preferences/shared_preferences.dart';

class EspIpRepository {
  static const _key = 'esp32_ip';

  Future<String?> getIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, ip);
  }

  Future<void> clearIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

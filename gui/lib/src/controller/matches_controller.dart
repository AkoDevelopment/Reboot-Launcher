import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:reboot_launcher/src/controller/backend_controller.dart';

class Match {
  final String serverId;
  final String playlist;
  final String displayName;
  final String region;
  final String status;
  final bool joinable;
  final int playerCount;
  final int? maxPlayers;
  final int aliveCount;
  final String phase;
  final int? pregameSecondsRemaining;
  final int? postmatchSecondsRemaining;
  final int? uptimeSeconds;

  const Match({
    required this.serverId,
    required this.playlist,
    required this.displayName,
    required this.region,
    required this.status,
    required this.joinable,
    required this.playerCount,
    required this.maxPlayers,
    required this.aliveCount,
    required this.phase,
    required this.pregameSecondsRemaining,
    required this.postmatchSecondsRemaining,
    required this.uptimeSeconds
  });

  factory Match.fromJson(Map<String, dynamic> json) => Match(
      serverId: json["serverId"] ?? "",
      playlist: json["playlist"] ?? "",
      displayName: json["displayName"] ?? json["playlist"] ?? "",
      region: json["region"] ?? "",
      status: json["status"] ?? "",
      joinable: json["joinable"] == true,
      playerCount: json["playerCount"] ?? 0,
      maxPlayers: json["maxPlayers"],
      aliveCount: json["aliveCount"] ?? 0,
      phase: json["phase"] ?? "",
      pregameSecondsRemaining: json["pregameSecondsRemaining"],
      postmatchSecondsRemaining: json["postmatchSecondsRemaining"],
      uptimeSeconds: json["uptimeSeconds"]
  );
}

/// Polls the backend's read-only /api/matches endpoint on a fixed interval.
/// Match status/lifecycle logic lives entirely server-side (matchLifecycleManager,
/// countdownManager, serverRegistry) -- this controller only fetches and exposes
/// whatever the backend already computed, it never derives state itself.
class MatchesController extends GetxController {
  static const Duration _pollInterval = Duration(seconds: 3);

  final BackendController _backendController = Get.find<BackendController>();
  final Rx<List<Match>> matches = Rx([]);
  final RxBool loading = RxBool(true);
  final RxBool error = RxBool(false);

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _poll() async {
    try {
      final host = _backendController.host.text;
      final port = _backendController.port.text;
      final uri = Uri.parse("http://$host:$port/api/matches");
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        error.value = true;
        return;
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      matches.value = decoded
          .map((entry) => Match.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false);
      error.value = false;
    } catch (_) {
      error.value = true;
    } finally {
      loading.value = false;
    }
  }

  Future<void> refresh() => _poll();
}

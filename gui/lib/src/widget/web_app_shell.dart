import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:reboot_common/common.dart';
import 'package:reboot_launcher/src/button/game_start_button.dart';
import 'package:reboot_launcher/src/button/version_selector.dart';
import 'package:reboot_launcher/src/controller/backend_controller.dart';
import 'package:reboot_launcher/src/controller/game_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

// TODO: replace with Project Ocean's real Discord invite + issue tracker URLs.
const String _kDiscordInviteUrl = "https://discord.gg/";
const String _kReportBugUrl = "https://discord.gg/";

/// Renders the custom HTML/CSS UI (gui/web_ui) inside a WebView2 surface and
/// bridges it to the native app: window controls, the real launch/import
/// logic from GameController/LaunchButton, and live status (online state,
/// selected build, username).
class WebAppShell extends StatefulWidget {
  const WebAppShell({Key? key}) : super(key: key);

  @override
  State<WebAppShell> createState() => _WebAppShellState();
}

class _WebAppShellState extends State<WebAppShell> {
  final WebviewController _controller = WebviewController();
  final GlobalKey<LaunchButtonState> _launchKey = GlobalKey();
  final GameController _gameController = Get.find<GameController>();
  final BackendController _backendController = Get.find<BackendController>();

  StreamSubscription? _webMessageSubscription;
  Timer? _pushStateTimer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final webUiDir = Directory("${installationDirectory.path}\\web_ui");
    final webUiAssetsDir = Directory("${webUiDir.path}\\assets");
    await webUiAssetsDir.create(recursive: true);
    for (final fileName in const ["index.html", "styles.css", "script.js"]) {
      final bytes = await rootBundle.load("web_ui/$fileName");
      await File("${webUiDir.path}\\$fileName").writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    }
    for (final fileName in const ["ocean.ico"]) {
      final bytes = await rootBundle.load("web_ui/assets/$fileName");
      await File("${webUiAssetsDir.path}\\$fileName").writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    }

    await _controller.initialize();
    await _controller.loadUrl(Uri.file("${webUiDir.path}\\index.html").toString());

    _webMessageSubscription = _controller.webMessage.listen(_onWebMessage);
    _pushStateTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pushState());

    if (!mounted) return;
    setState(() => _ready = true);
  }

  void _onWebMessage(dynamic message) {
    if (message is! Map) return;
    final action = message["action"];
    switch (action) {
      case "minimize":
        windowManager.minimize();
        break;
      case "maximize":
        windowManager.isMaximized().then((maximized) =>
            maximized ? windowManager.unmaximize() : windowManager.maximize());
        break;
      case "close":
        windowManager.close();
        break;
      case "launchFortnite":
        _launchKey.currentState?.trigger();
        break;
      case "importBuild":
        VersionSelector.openImportDialog(null);
        break;
      case "removeBuild":
        final version = _gameController.selectedVersion.value;
        if (version != null) {
          _gameController.removeVersion(version);
        }
        break;
      case "startDrag":
        windowManager.startDragging();
        break;
      case "openDiscord":
        launchUrlString(_kDiscordInviteUrl);
        break;
      case "reportBug":
        launchUrlString(_kReportBugUrl);
        break;
      case "openInstallDir":
        launchUrl(installationDirectory.uri);
        break;
      case "startTutorial":
        // TODO: the onboarding tour targets the old native sidebar/pages and
        // needs to be rebuilt against this webview UI.
        break;
    }
  }

  void _pushState() {
    final version = _gameController.selectedVersion.value;
    final online = _backendController.started.value;
    final started = _gameController.started.value;
    final username = _gameController.username.text;

    final script = '''
      (function() {
        const statusState = document.querySelector(".status-state");
        const statusDot = document.querySelector(".status-dot");
        if (statusState) {
          statusState.textContent = ${jsonEncode(online ? "ONLINE" : "OFFLINE")};
          statusState.classList.toggle("online", ${online});
        }
        if (statusDot) statusDot.classList.toggle("online", ${online});

        const heroActions = document.getElementById("hero-actions");
        if (heroActions) heroActions.dataset.hasVersion = ${jsonEncode(version != null)};

        const launchBtn = document.getElementById("launch-btn");
        if (launchBtn) launchBtn.textContent = ${jsonEncode(started ? "Close Fortnite" : "Launch Fortnite")};

        const versionBadge = document.getElementById("version-badge");
        if (versionBadge) versionBadge.textContent = ${jsonEncode(version?.gameVersion ?? "")};

        const userName = document.querySelector(".user-name");
        if (userName) userName.textContent = ${jsonEncode(username)};
      })();
    ''';

    _controller.executeScript(script);
  }

  String jsonEncode(Object? value) => value == null ? "null" : '"${value.toString().replaceAll('"', '\\"')}"';

  @override
  void dispose() {
    _webMessageSubscription?.cancel();
    _pushStateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          if (_ready) Positioned.fill(child: Webview(_controller)),
          // Mounted off-screen so the existing LaunchButton/GameController
          // logic can be triggered via _launchKey without duplicating it.
          Positioned(
            left: -9999,
            child: SizedBox(
              width: 1,
              height: 1,
              child: LaunchButton(
                key: _launchKey,
                host: false,
                startLabel: "Launch Fortnite",
                stopLabel: "Close Fortnite",
              ),
            ),
          ),
        ],
      );
}

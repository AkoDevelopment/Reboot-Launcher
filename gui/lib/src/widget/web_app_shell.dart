import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:reboot_common/common.dart';
import 'package:reboot_launcher/src/button/game_start_button.dart';
import 'package:reboot_launcher/src/button/version_selector.dart';
import 'package:reboot_launcher/src/controller/auth_controller.dart';
import 'package:reboot_launcher/src/controller/backend_controller.dart';
import 'package:reboot_launcher/src/controller/game_controller.dart';
import 'package:reboot_launcher/src/controller/hosting_controller.dart';
import 'package:reboot_launcher/src/controller/server_browser_controller.dart';
import 'package:reboot_launcher/src/message/login.dart';
import 'package:reboot_launcher/src/messenger/dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

const String _kDiscordInviteUrl = "https://discord.gg/projectocean";
// No separate issue tracker yet, so bug reports also go to Discord.
const String _kReportBugUrl = "https://discord.gg/projectocean";

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
  final HostingController _hostingController = Get.find<HostingController>();
  final ServerBrowserController _serverBrowserController = Get.find<ServerBrowserController>();
  final AuthController _authController = Get.find<AuthController>();

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
    for (final fileName in const ["ocean.ico", "user.png"]) {
      final bytes = await rootBundle.load("web_ui/assets/$fileName");
      await File("${webUiAssetsDir.path}\\$fileName").writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    }

    await _controller.initialize();
    await _controller.loadUrl(Uri.file("${webUiDir.path}\\index.html").toString());

    _webMessageSubscription = _controller.webMessage.listen(_onWebMessage);
    _pushState();
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
        _exitApp();
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
      case "login":
        showRebootDialog(builder: (context) => const LoginDialog());
        break;
      case "logout":
        _authController.logout();
        break;
    }
  }

  Future<void> _exitApp() async {
    try {
      await windowManager.hide();
    } catch (_) {}

    try {
      await _serverBrowserController.removeServer(_hostingController.uuid);
    } catch (_) {}

    try {
      await _backendController.stop();
    } catch (_) {}

    try {
      _gameController.instance.value?.kill();
    } catch (_) {}

    try {
      _hostingController.instance.value?.kill();
    } catch (_) {}

    try {
      await stopDownloadServer();
    } catch (_) {}

    exit(0);
  }

  void _pushState() {
    final version = _gameController.selectedVersion.value;
    final online = _backendController.started.value;
    final started = _gameController.started.value;
    final loggedIn = _authController.loggedIn.value;
    final username = _authController.username.value;
    final avatarUrl = _authController.avatarUrl.value;

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

        const loginBtn = document.getElementById("login-btn");
        const userPill = document.getElementById("user-pill");
        if (loginBtn) loginBtn.hidden = ${loggedIn};
        if (userPill) userPill.hidden = ${!loggedIn};

        const userName = document.getElementById("user-name");
        if (userName) userName.textContent = ${jsonEncode(username ?? "")};

        const userAvatar = document.getElementById("user-avatar");
        if (userAvatar && ${jsonEncode(avatarUrl)} !== null) userAvatar.src = ${jsonEncode(avatarUrl)};

        const playSubtitle = document.getElementById("play-subtitle");
        if (playSubtitle) {
          playSubtitle.innerHTML = ${loggedIn}
            ? 'Play now, <span class="accent">' + ${jsonEncode(username ?? "")} + '!</span>'
            : 'Please <a href="#" id="play-subtitle-login">login</a> to play.';
        }
      })();
    ''';

    _controller.executeScript(script).then((_) {
      // The login link inside play-subtitle gets replaced via innerHTML above,
      // so its click listener needs to be re-attached every push.
      _controller.executeScript('''
        document.getElementById("play-subtitle-login")?.addEventListener("click", (event) => {
          event.preventDefault();
          window.chrome.webview.postMessage({ action: "login" });
        });
      ''');
    });
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

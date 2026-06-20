import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:reboot_common/common.dart';
import 'package:reboot_launcher/main.dart';
import 'package:version/version.dart';

/// Information about a newer launcher version found on GitHub Releases.
class LauncherUpdate {
  final Version version;
  final String downloadUrl;

  const LauncherUpdate(this.version, this.downloadUrl);
}

/// Set once an update is found. LaunchButton checks this to block launching
/// Fortnite until the user installs the new version.
final Rx<LauncherUpdate?> pendingLauncherUpdate = Rx<LauncherUpdate?>(null);

const String _kReleasesApiUrl = "https://api.github.com/repos/AkoDevelopment/Reboot-Launcher/releases/latest";

/// Checks GitHub Releases for a newer launcher version than the one
/// currently running. Returns the update info (and sets [pendingLauncherUpdate])
/// if one is found, otherwise null.
Future<LauncherUpdate?> checkLauncherUpdate() async {
  if (appVersion == null) {
    return null;
  }

  try {
    final response = await http.get(
        Uri.parse(_kReleasesApiUrl),
        headers: const {"Accept": "application/vnd.github+json"}
    );
    if (response.statusCode != 200) {
      return null;
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = json["tag_name"] as String?;
    if (tagName == null) {
      return null;
    }

    final latestVersion = Version.parse(tagName.startsWith("v") ? tagName.substring(1) : tagName);
    if (latestVersion <= appVersion!) {
      return null;
    }

    final assets = (json["assets"] as List?) ?? const [];
    String? downloadUrl;
    for (final asset in assets) {
      final name = (asset["name"] as String?)?.toLowerCase() ?? "";
      if (name.endsWith(".exe")) {
        downloadUrl = asset["browser_download_url"] as String?;
        break;
      }
    }

    if (downloadUrl == null) {
      return null;
    }

    final update = LauncherUpdate(latestVersion, downloadUrl);
    pendingLauncherUpdate.value = update;
    return update;
  } catch (error) {
    log("[UPDATER] Cannot check for updates: $error");
    return null;
  }
}

/// Downloads the installer for [update] to a temp file and launches it as a
/// detached process, then exits this app so the installer can overwrite its
/// files. Throws if the download fails.
Future<void> downloadAndRunUpdate(LauncherUpdate update) async {
  final response = await http.Client().send(http.Request("GET", Uri.parse(update.downloadUrl)));
  if (response.statusCode != 200) {
    throw Exception("Download failed with status ${response.statusCode}");
  }

  final filePath = "${Directory.systemTemp.path}${Platform.pathSeparator}ProjectOceanUpdate.exe";
  final file = File(filePath);
  final sink = file.openWrite();

  await response.stream.pipe(sink);

  await Process.start(filePath, const [], mode: ProcessStartMode.detached);
  exit(0);
}

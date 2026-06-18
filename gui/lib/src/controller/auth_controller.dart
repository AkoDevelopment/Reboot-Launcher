import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:reboot_launcher/main.dart';

class AuthController extends GetxController {
  static const String storageName = "v3_auth_storage";

  late final GetStorage? _storage;
  late final RxBool loggedIn;
  late final Rxn<String> username;
  late final Rxn<String> avatarUrl;
  late final Rxn<String> accountId;
  late final Rxn<String> accessToken;

  AuthController() {
    _storage = appWithNoStorage ? null : GetStorage(storageName);
    loggedIn = RxBool(_storage?.read("logged_in") ?? false);
    username = Rxn(_storage?.read("username"));
    avatarUrl = Rxn(_storage?.read("avatar_url"));
    accountId = Rxn(_storage?.read("account_id"));
    accessToken = Rxn(_storage?.read("access_token"));
  }

  /// Logs in against Project Ocean's backend using the same Epic-style OAuth
  /// password grant that the actual game client uses. Returns null on
  /// success, or an error message to show the user.
  Future<String?> login({
    required String host,
    required String port,
    required String email,
    required String password
  }) async {
    try {
      final uri = Uri.parse("http://$host:$port/account/api/oauth/token");
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": "Basic ${base64Encode(utf8.encode("projectOceanLauncher:launcher"))}"
        },
        body: {
          "grant_type": "password",
          "username": email,
          "password": password
        }
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      if (response.statusCode != 200) {
        return json["errorMessage"] ?? "Login failed. Please check your credentials.";
      }

      username.value = json["displayName"];
      avatarUrl.value = json["avatarUrl"];
      accountId.value = json["account_id"];
      accessToken.value = json["access_token"];
      loggedIn.value = true;

      _storage?.write("logged_in", true);
      _storage?.write("username", username.value);
      _storage?.write("avatar_url", avatarUrl.value);
      _storage?.write("account_id", accountId.value);
      _storage?.write("access_token", accessToken.value);

      return null;
    } catch (error) {
      return "Could not reach the backend. Is it running?";
    }
  }

  void logout() {
    loggedIn.value = false;
    username.value = null;
    avatarUrl.value = null;
    accountId.value = null;
    accessToken.value = null;

    _storage?.remove("logged_in");
    _storage?.remove("username");
    _storage?.remove("avatar_url");
    _storage?.remove("account_id");
    _storage?.remove("access_token");
  }
}

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:reboot_launcher/src/controller/auth_controller.dart';
import 'package:reboot_launcher/src/controller/backend_controller.dart';
import 'package:reboot_launcher/src/messenger/dialog.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({Key? key}) : super(key: key);

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final AuthController _authController = Get.find<AuthController>();
  final BackendController _backendController = Get.find<BackendController>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();
  final Rx<_LoginState> _state = Rx(_LoginState.inputData);
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
      key: _formKey,
      child: Obx(() {
        switch (_state.value) {
          case _LoginState.inputData:
            return FormDialog(
                content: _body,
                buttons: _buttons
            );
          case _LoginState.loading:
            return const ProgressDialog(
                text: "Logging in...",
                showButton: false
            );
          case _LoginState.error:
            return InfoDialog.ofOnly(
                text: _errorMessage ?? "Login failed.",
                button: DialogButton(
                    text: "Ok",
                    type: ButtonType.only,
                    onTap: () => _state.value = _LoginState.inputData
                )
            );
          case _LoginState.success:
            return const InfoDialog(
                text: "Successfully logged in!"
            );
        }
      })
  );

  Widget get _body => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InfoLabel(
        label: "Email",
        child: TextFormBox(
            controller: _emailController,
            placeholder: "you@example.com",
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => value == null || value.isEmpty ? "Email is required." : null,
            decoration: WidgetStateProperty.resolveWith((states) => BoxDecoration(
                color: const Color(0xFF12141A),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                    color: states.contains(WidgetState.focused) ? const Color(0xFF2F7AF0) : const Color(0xFF232730),
                    width: states.contains(WidgetState.focused) ? 1.4 : 1.0
                )
            ))
        ),
      ),
      const SizedBox(height: 16.0),
      InfoLabel(
        label: "Password",
        child: TextFormBox(
            controller: _passwordController,
            placeholder: "Your password",
            obscureText: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => value == null || value.isEmpty ? "Password is required." : null,
            decoration: WidgetStateProperty.resolveWith((states) => BoxDecoration(
                color: const Color(0xFF12141A),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                    color: states.contains(WidgetState.focused) ? const Color(0xFF2F7AF0) : const Color(0xFF232730),
                    width: states.contains(WidgetState.focused) ? 1.4 : 1.0
                )
            ))
        ),
      ),
      const SizedBox(height: 16.0)
    ],
  );

  List<DialogButton> get _buttons => [
    DialogButton(type: ButtonType.secondary),
    DialogButton(
        text: "Login",
        type: ButtonType.primary,
        onTap: _login
    )
  ];

  void _login() async {
    if (_formKey.currentState?.validate() != true) return;

    _state.value = _LoginState.loading;

    final error = await _authController.login(
        host: _backendController.host.text,
        port: _backendController.port.text,
        email: _emailController.text.trim(),
        password: _passwordController.text
    );

    if (error != null) {
      _errorMessage = error;
      _state.value = _LoginState.error;
      return;
    }

    _state.value = _LoginState.success;
  }
}

enum _LoginState {
  inputData,
  loading,
  error,
  success
}

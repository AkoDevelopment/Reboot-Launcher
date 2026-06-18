import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({Key? key}) : super(key: key);

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() {});

  @override
  void onWindowUnmaximize() => setState(() {});

  @override
  Widget build(BuildContext context) => Container(
        height: 32,
        color: FluentTheme.of(context).micaBackgroundColor,
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                child: Row(
                  children: [
                    const SizedBox(width: 12.0),
                    SizedBox.square(
                        dimension: 16,
                        child: Image.asset("assets/images/auties.png")
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      "Project Ocean",
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
              ),
            ),
            _TitleBarButton(
              icon: FluentIcons.chrome_minimize,
              onPressed: () => windowManager.minimize(),
            ),
            FutureBuilder<bool>(
              future: windowManager.isMaximized(),
              builder: (context, snapshot) => _TitleBarButton(
                icon: snapshot.data == true
                    ? FluentIcons.chrome_restore
                    : WindowsIcons.chrome_maximize,
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                  setState(() {});
                },
              ),
            ),
            _TitleBarButton(
              icon: FluentIcons.chrome_close,
              hoverColor: Colors.red,
              onPressed: () => windowManager.close(),
            ),
          ],
        ),
      );
}

class _TitleBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;

  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
  });

  @override
  Widget build(BuildContext context) => HoverButton(
        onPressed: onPressed,
        builder: (context, states) => Container(
          width: 46,
          height: 32,
          color: states.isHovered
              ? (hoverColor ?? FluentTheme.of(context).resources.controlFillColorSecondary)
              : Colors.transparent,
          child: Icon(icon, size: 12.0),
        ),
      );
}

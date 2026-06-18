import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:reboot_launcher/src/button/game_start_button.dart';
import 'package:reboot_launcher/src/button/version_selector.dart';
import 'package:reboot_launcher/src/controller/game_controller.dart';
import 'package:reboot_launcher/src/pager/abstract_page.dart';
import 'package:reboot_launcher/src/pager/page_type.dart';

class WhatsNewEntry {
  final String title;
  final String description;
  final String date;
  final bool unread;
  final Color accentColor;

  const WhatsNewEntry({
    required this.title,
    required this.description,
    required this.date,
    required this.unread,
    required this.accentColor,
  });
}

const List<WhatsNewEntry> _whatsNewEntries = [
  WhatsNewEntry(
    title: "CONTENT UPDATE #5",
    description: "Project Ocean's final content update for Season 8 is finally here!",
    date: "5/8/2026",
    unread: true,
    accentColor: Color(0xFF7B3FF2),
  ),
  WhatsNewEntry(
    title: "CONTENT UPDATE #4",
    description: "Content Update #4 Week 7 challenges have been added.",
    date: "4/13/2026",
    unread: true,
    accentColor: Color(0xFFCC8B1A),
  ),
  WhatsNewEntry(
    title: "CONTENT UPDATE #3",
    description: "Pirate Cannons and Reboot Vans are now live across the map.",
    date: "3/2/2026",
    unread: false,
    accentColor: Color(0xFF1A8FCC),
  ),
];

class HomePage extends AbstractPage {
  const HomePage({Key? key}) : super(key: key);

  @override
  AbstractPageState<HomePage> createState() => _HomePageState();

  @override
  bool hasButton(String? pageName) => false;

  @override
  String get name => "Home";

  @override
  String get iconAsset => "assets/images/play.png";

  @override
  PageType get type => PageType.home;
}

class _HomePageState extends AbstractPageState<HomePage> {
  final GameController _gameController = Get.find<GameController>();
  int _whatsNewPage = 0;

  @override
  List<Widget> get settings => [];

  @override
  Widget? get button => null;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(),
          const SizedBox(height: 24.0),
          _buildImportBuildSection(),
          const SizedBox(height: 32.0),
          _buildWhatsNewHeader(),
          const SizedBox(height: 12.0),
          _buildWhatsNewCarousel(),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() => Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1E3D),
              Color(0xFF13355C),
            ],
          ),
        ),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A6FE0),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Text(
                "PROJECT OCEAN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.0,
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            const Text(
              "X Marks The Spot",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 34.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              "Season 8 · Pirate Cannons, Ballers & Reboot Vans",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.0,
              ),
            ),
            const SizedBox(height: 20.0),
            Obx(() {
              final version = _gameController.selectedVersion.value;
              if (version == null) {
                return Button(
                  onPressed: () => VersionSelector.openImportDialog(null),
                  child: const Text("Import a build to get started"),
                );
              }

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      version.gameVersion,
                      style: const TextStyle(color: Colors.white, fontSize: 12.0),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  LaunchButton(
                    startLabel: "Launch Fortnite",
                    stopLabel: "Close Fortnite",
                    host: false,
                  ),
                  const SizedBox(width: 12.0),
                  IconButton(
                    icon: Icon(FluentIcons.delete, color: Colors.red),
                    onPressed: () => _gameController.removeVersion(version),
                  ),
                ],
              );
            }),
          ],
        ),
      );

  Widget _buildImportBuildSection() => Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(FluentIcons.import, size: 22.0),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Import a build",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    "Only Fortnite 8.51-CL-6165369 is supported on Project Ocean.",
                    style: TextStyle(fontSize: 12.0),
                  ),
                ],
              ),
            ),
            Button(
              onPressed: () => VersionSelector.openImportDialog(null),
              child: const Text("Import"),
            ),
          ],
        ),
      );

  Widget _buildWhatsNewHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "What's new",
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text("${_whatsNewPage + 1} / ${_whatsNewEntries.length}"),
              const SizedBox(width: 8.0),
              IconButton(
                icon: const Icon(FluentIcons.chevron_left),
                onPressed: _whatsNewPage > 0
                    ? () => setState(() => _whatsNewPage--)
                    : null,
              ),
              IconButton(
                icon: const Icon(FluentIcons.chevron_right),
                onPressed: _whatsNewPage < _whatsNewEntries.length - 1
                    ? () => setState(() => _whatsNewPage++)
                    : null,
              ),
              const SizedBox(width: 8.0),
              if (_whatsNewEntries.any((entry) => entry.unread))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    "${_whatsNewEntries.where((entry) => entry.unread).length} unread",
                    style: const TextStyle(color: Colors.white, fontSize: 12.0),
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _buildWhatsNewCarousel() => Row(
        children: _whatsNewEntries
            .skip(_whatsNewPage * 2)
            .take(2)
            .map((entry) => Expanded(child: _buildWhatsNewCard(entry)))
            .toList(),
      );

  Widget _buildWhatsNewCard(WhatsNewEntry entry) => Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: FluentTheme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 110,
                    height: 90,
                    decoration: BoxDecoration(
                      color: entry.accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        bottomLeft: Radius.circular(8.0),
                      ),
                    ),
                  ),
                  if (entry.unread)
                    Positioned(
                      top: 8.0,
                      left: 8.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Text(
                          "UNREAD",
                          style: TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        entry.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: FluentTheme.of(context).resources.controlFillColorSecondary,
                        ),
                        child: Text(entry.date, style: const TextStyle(fontSize: 10.0)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

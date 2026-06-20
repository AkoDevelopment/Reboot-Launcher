import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as fluentIcons show FluentIcons;
import 'package:get/get.dart';
import 'package:reboot_launcher/src/controller/matches_controller.dart';
import 'package:reboot_launcher/src/pager/abstract_page.dart';
import 'package:reboot_launcher/src/pager/page_type.dart';
import 'package:reboot_launcher/src/tile/setting_tile.dart';
import 'package:reboot_launcher/src/util/translations.dart';

class MatchesPage extends AbstractPage {
  const MatchesPage({Key? key}) : super(key: key);

  @override
  AbstractPageState<MatchesPage> createState() => _MatchesPageState();

  @override
  bool hasButton(String? pageName) => false;

  @override
  String get name => translations.matchesName;

  @override
  String get iconAsset => "assets/images/server_browser.png";

  @override
  PageType get type => PageType.matches;
}

class _MatchesPageState extends AbstractPageState<MatchesPage> {
  final MatchesController _matchesController = Get.find<MatchesController>();
  final Rx<String> _filter = Rx(_kAllFilter);

  static const String _kAllFilter = "__all__";

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final matches = _matchesController.matches.value;
      if (_matchesController.loading.value && matches.isEmpty) {
        return const Center(
          child: ProgressRing(),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(matches),
          const SizedBox(height: 16.0),
          Expanded(
            child: _buildList(matches),
          )
        ],
      );
    });
  }

  Widget _buildFilterBar(List<Match> matches) {
    final playlists = <String, String>{};
    for (final match in matches) {
      playlists[match.playlist] = match.displayName;
    }

    return Obx(() => Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildFilterChip(_kAllFilter, translations.matchesFilterAll),
        for (final entry in playlists.entries)
          _buildFilterChip(entry.key, entry.value)
      ],
    ));
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _filter.value == value;
    return ToggleButton(
      checked: selected,
      onChanged: (_) => _filter.value = value,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(label),
      ),
    );
  }

  Widget _buildList(List<Match> matches) {
    final filtered = _filter.value == _kAllFilter
        ? matches
        : matches.where((match) => match.playlist == _filter.value).toList(growable: false);

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildMatchTile(filtered[index]),
    );
  }

  Widget _buildEmptyState() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        translations.matchesNoneTitle,
        style: FluentTheme.of(context).typography.titleLarge,
      ),
      Text(
        translations.matchesNoneSubtitle,
        style: FluentTheme.of(context).typography.body,
      ),
    ],
  );

  SettingTile _buildMatchTile(Match match) {
    final maxPlayers = match.maxPlayers;
    return SettingTile(
      icon: Icon(
        match.joinable ? fluentIcons.FluentIcons.checkmark_circle_24_regular : fluentIcons.FluentIcons.circle_24_regular,
      ),
      title: Text(
        "${match.displayName} • ${match.status}",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        maxPlayers != null
            ? "${translations.matchesPlayerCount(match.playerCount, maxPlayers)} • ${translations.matchesAliveCount(match.aliveCount)}"
            : translations.matchesAliveCount(match.aliveCount),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        SettingTile(
          icon: Icon(fluentIcons.FluentIcons.server_24_regular),
          title: Text(translations.matchesServerId),
          subtitle: Text(match.serverId),
        ),
        SettingTile(
          icon: Icon(fluentIcons.FluentIcons.globe_24_regular),
          title: Text(translations.matchesRegion),
          subtitle: Text(match.region),
        ),
        SettingTile(
          icon: Icon(fluentIcons.FluentIcons.clock_24_regular),
          title: Text(translations.matchesUptime),
          subtitle: Text(_formatUptime(match.uptimeSeconds)),
        ),
      ],
    );
  }

  String _formatUptime(int? seconds) {
    if (seconds == null) {
      return "-";
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes}m ${remainingSeconds}s";
  }

  @override
  Widget? get button => null;

  @override
  List<Widget> get settings => [];
}

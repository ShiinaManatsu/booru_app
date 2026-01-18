import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/settings/language.dart';
import 'package:booru_app/utils/platform.dart';
import 'package:booru_app/utils/windows_folder_picker.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _limit = 50;
  String _yandePath = '';
  String _konachanPath = '';

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final limit = await AppSettings.postLimit;
    final y = await AppSettings.savePath(client: ClientType.Yande);
    final k = await AppSettings.savePath(client: ClientType.Konachan);
    setState(() {
      _limit = limit;
      _yandePath = y;
      _konachanPath = k;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      platform: DevicePlatform.web,
      lightTheme: const SettingsThemeData(settingsListBackground: Colors.transparent),
      darkTheme: const SettingsThemeData(settingsListBackground: Colors.transparent),
      sections: [
        SettingsSection(
          title: Text(language.content.settings),
          tiles: [
            CustomSettingsTile(
              child: _SettingsRow(
                leading: const Icon(Icons.public),
                title: const Text('Site'),
                trailing: _InlineToggle<ClientType>(
                  value: AppSettings.currentClient,
                  items: const [
                    _InlineToggleItem(value: ClientType.Yande, label: 'yande.re'),
                    _InlineToggleItem(value: ClientType.Konachan, label: 'konachan.com'),
                  ],
                  onChanged: (next) async {
                    if (next == AppSettings.currentClient) return;
                    await AppSettings.setCurrentClient(next);
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ),
            ),
            SettingsTile.switchTile(
              initialValue: AppSettings.safeMode,
              onToggle: (v) async {
                await SharedPreferencesExtension.setTyped<bool>('safemode', v);
                setState(() => AppSettings.safeMode = v);
              },
              leading: const Icon(Icons.shield_moon),
              title: Text('${language.content.safe} ${language.content.mode}'),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.folder),
              title: const Text('Yande save path'),
              value: Text(_yandePath.isEmpty ? 'Not set' : _yandePath),
              onPressed: (_) => _pickFolder(ClientType.Yande),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.folder_special),
              title: const Text('Konachan save path'),
              value: Text(_konachanPath.isEmpty ? 'Not set' : _konachanPath),
              onPressed: (_) => _pickFolder(ClientType.Konachan),
            ),
            CustomSettingsTile(
              child: _SettingsRow(
                leading: const Icon(Icons.image),
                title: Text('${language.content.preview} quality'),
                trailing: _InlineToggle<PreviewQuality>(
                  value: AppSettings.previewQuality,
                  items: const [
                    _InlineToggleItem(value: PreviewQuality.Low, label: 'Low'),
                    _InlineToggleItem(value: PreviewQuality.Medium, label: 'Medium'),
                  ],
                  onChanged: (next) async {
                    if (next == AppSettings.previewQuality) return;
                    setState(() => AppSettings.previewQuality = next);
                    await SharedPreferencesExtension.setTyped('PreviewQuality', next.name);
                  },
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: Text(language.content.singlePagePostLoadLimit),
          tiles: [
            SettingsTile.navigation(
              leading: const Icon(Icons.list),
              title: Text('${language.content.currentLimit}: ${_limit.toInt()}'),
              onPressed: (_) => _showLimitDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showLimitDialog() async {
    double temp = _limit;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(language.content.singlePagePostLoadLimit),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${language.content.currentLimit}: ${temp.toInt()}'),
              Slider(
                value: temp,
                min: 40,
                max: 100,
                divisions: 60,
                onChanged: (v) => setLocal(() => temp = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, temp), child: const Text('Save')),
        ],
      ),
    );

    if (result != null) {
      setState(() => _limit = result);
      await AppSettings.setPostLimit(result);
    }
  }

  Future<void> _pickFolder(ClientType client) async {
    final existing = await AppSettings.savePath(client: client);

    String? result;
    if (isWindows) {
      result = await pickWindowsFolder(
        title: 'Select folder',
        initialDirectory: existing.isEmpty ? null : existing,
      );
      // On Windows, `null` typically means the user cancelled the picker (or it failed).
      // Don't pop a manual-input dialog in that case.
      if (result == null) return;
    } else {
      // Fallback: manual input (keeps Android/web/etc usable).
      result = await _manualFolderInput(existing);
    }

    if (result != null && result.trim().isNotEmpty) {
      await AppSettings.setSavePath(result.trim(), client: client);
      await _hydrate();
    }
  }

  Future<String?> _manualFolderInput(String initial) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set folder path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder path'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }
}

class _InlineToggleItem<T> {
  final T value;
  final String label;

  const _InlineToggleItem({required this.value, required this.label});
}

class _InlineToggle<T> extends StatelessWidget {
  const _InlineToggle({required this.value, required this.items, required this.onChanged});

  final T value;
  final List<_InlineToggleItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = items.map((e) => e.value == value).toList(growable: false);
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(10),
        constraints: const BoxConstraints(minHeight: 34),
        isSelected: selected,
        onPressed: (index) => onChanged(items[index].value),
        fillColor: colorScheme.primary.withAlpha((0.18 * 255).round()),
        selectedColor: colorScheme.primary,
        color: textColor,
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(e.label),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.leading, required this.title, required this.trailing});

  final Widget leading;
  final Widget title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconTheme.merge(
            data: IconThemeData(color: Theme.of(context).iconTheme.color),
            child: leading,
          ),
          const SizedBox(width: 16),
          Expanded(child: DefaultTextStyle.merge(style: const TextStyle(fontSize: 16), child: title)),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

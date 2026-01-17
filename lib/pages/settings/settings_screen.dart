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
            SettingsTile.navigation(
              leading: const Icon(Icons.image),
              title: Text('${language.content.preview} quality'),
              value: Text(AppSettings.previewQuality.name),
              onPressed: (_) => _pickPreviewQuality(),
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

  Future<void> _pickPreviewQuality() async {
    var temp = AppSettings.previewQuality;
    final result = await showDialog<PreviewQuality>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${language.content.preview} quality'),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return DropdownButtonFormField<PreviewQuality>(
              initialValue: temp,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: PreviewQuality.Low, child: Text('Low (preview_url)')),
                DropdownMenuItem(value: PreviewQuality.Medium, child: Text('Medium (sample_url)')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setLocal(() => temp = v);
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, temp), child: const Text('Save')),
        ],
      ),
    );

    if (result == null) return;
    setState(() => AppSettings.previewQuality = result);
    await SharedPreferencesExtension.setTyped('PreviewQuality', result.name);
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

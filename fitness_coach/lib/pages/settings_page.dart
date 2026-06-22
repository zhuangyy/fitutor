import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(context, '教练'),
              SwitchListTile(
                title: const Text('语音播报'),
                value: settings.ttsEnabled,
                onChanged: (_) => settings.toggleTts(),
              ),
              SwitchListTile(
                title: const Text('震动反馈'),
                value: settings.hapticEnabled,
                onChanged: (_) => settings.toggleHaptic(),
              ),
              ListTile(
                title: const Text('间隔提醒'),
                subtitle: const Text('倒计时中每隔一段时间播报剩余秒数'),
                trailing: Text(settings.reminderIntervalLabel,
                    style: Theme.of(context).textTheme.bodyLarge),
                onTap: () => _showIntervalPicker(context, settings),
              ),
              const Divider(),
              _buildSectionTitle(context, '界面'),
              SwitchListTile(
                title: const Text('快捷暂停'),
                subtitle: const Text('训练/休息时点击屏幕任意位置暂停'),
                value: settings.tapToPause,
                onChanged: (_) => settings.toggleTapToPause(),
              ),
              const Divider(),
              _buildSectionTitle(context, '关于'),
              ListTile(
                title: const Text('版本'),
                trailing: Text('v1.2.1',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

Future<void> _showIntervalPicker(
    BuildContext context, SettingsProvider settings) async {
  const options = [0, 5, 10, 15, 20, 30];
  const labels = ['关闭', '5秒', '10秒', '15秒', '20秒', '30秒'];
  await showDialog<void>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('间隔提醒'),
      children: List.generate(options.length, (i) {
        final selected = options[i] == settings.reminderInterval;
        return RadioListTile<int>(
          title: Text(labels[i]),
          value: options[i],
          groupValue: settings.reminderInterval,
          selected: selected,
          onChanged: (v) {
            settings.setReminderInterval(v!);
            Navigator.pop(ctx);
          },
        );
      }),
    ),
  );
}

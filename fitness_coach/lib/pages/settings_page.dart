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
              _buildSectionTitle(context, '通知'),
              SwitchListTile(
                title: const Text('训练提醒'),
                subtitle: settings.reminderEnabled
                    ? Text('每天 ${settings.reminderTime.format(context)}')
                    : const Text('关闭'),
                value: settings.reminderEnabled,
                onChanged: (v) => settings.toggleReminder(v),
              ),
              if (settings.reminderEnabled)
                ListTile(
                  title: const Text('提醒时间'),
                  trailing:
                      Text(settings.reminderTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: settings.reminderTime,
                    );
                    if (time != null) {
                      await settings.setReminderTime(time);
                    }
                  },
                ),
              const Divider(),
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
              const Divider(),
              _buildSectionTitle(context, '关于'),
              const ListTile(
                  title: Text('版本'), trailing: Text('v1.0.0')),
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
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(
              context
                  .select((ThemeProvider p) => p.themeMode.name.toUpperCase()),
            ),
            leading: const Icon(Icons.palette),
            onTap: () => _showThemeDialog(context),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('LIGHT'),
                value: ThemeMode.light,
                groupValue: context.watch<ThemeProvider>().themeMode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeProvider>().setThemeMode(value);
                  }
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('DARK'),
                value: ThemeMode.dark,
                groupValue: context.watch<ThemeProvider>().themeMode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeProvider>().setThemeMode(value);
                  }
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('SYSTEM'),
                value: ThemeMode.system,
                groupValue: context.watch<ThemeProvider>().themeMode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeProvider>().setThemeMode(value);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

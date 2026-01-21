import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:root_plus/root_plus.dart';

import 'package:update_device_id/theme/app_colors.dart';
import 'package:update_device_id/widgets/ssaid_logo.dart';

class DeviceIdHomePage extends StatefulWidget {
  const DeviceIdHomePage({super.key});

  @override
  State<DeviceIdHomePage> createState() => _DeviceIdHomePageState();
}

class _DeviceIdHomePageState extends State<DeviceIdHomePage> {
  final TextEditingController _newIdController = TextEditingController();

  List<AppInfo> _apps = <AppInfo>[];
  AppInfo? _selectedApp;

  bool _loadingApps = true;
  bool _loadingSsaid = false;
  bool _updatingSsaid = false;
  bool _rootReady = false;
  bool _rootChecked = false;

  String? _currentSsaid;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _newIdController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _requestRoot();
    await _loadApps();
  }

  Future<void> _requestRoot() async {
    setState(() {
      _rootChecked = false;
      _statusMessage = 'Requesting root access...';
    });

    bool hasRoot = false;
    try {
      hasRoot = await RootPlus.requestRootAccess();
    } catch (e) {
      hasRoot = false;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _rootReady = hasRoot;
      _rootChecked = true;
      _statusMessage = hasRoot
          ? 'Root access granted. Ready to read and patch SSAID entries.'
          : null;
    });
  }

  Future<void> _loadApps() async {
    setState(() {
      _loadingApps = true;
    });

    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: false,
        withIcon: true,
      );
      final filtered = apps.toList();
      filtered.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = filtered;
        _loadingApps = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingApps = false;
        _statusMessage = 'Failed to load installed apps: $e';
      });
    }
  }

  Future<void> _selectApp(AppInfo app) async {
    setState(() {
      _selectedApp = app;
      _currentSsaid = null;
      _newIdController.text = '';
    });
    await _fetchSsaid();
  }

  List<AppInfo> _filterApps(List<AppInfo> apps, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return apps;
    }
    return apps.where((app) {
      return app.name.toLowerCase().contains(normalized) ||
          app.packageName.toLowerCase().contains(normalized);
    }).toList();
  }

  Future<void> _fetchSsaid() async {
    if (_selectedApp == null) {
      return;
    }
    if (!await _ensureRoot()) {
      return;
    }

    setState(() {
      _loadingSsaid = true;
      _statusMessage = 'Reading SSAID entry...';
    });

    try {
      final output = await RootPlus.executeRootCommand(
        _buildReadCommand(_selectedApp!.packageName),
      );
      if (output.contains('ABX_MISSING')) {
        if (!mounted) {
          return;
        }
        setState(() {
          _loadingSsaid = false;
          _statusMessage =
              'ABX tools are required on Android 12+ (abx2xml/xml2abx).';
        });
        return;
      }
      final ssaid = _extractSsaid(output);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentSsaid = ssaid;
        _loadingSsaid = false;
        if (ssaid == null) {
          _statusMessage =
              'No SSAID entry found. Launch the app once to create it.';
        } else {
          _statusMessage = 'SSAID loaded for ${_selectedApp!.name}.';
        }
      });
    } on RootCommandException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingSsaid = false;
        _statusMessage = 'Root command failed: ${e.message}';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingSsaid = false;
        _statusMessage = 'Failed to read SSAID: $e';
      });
    }
  }

  Future<void> _updateSsaid() async {
    final app = _selectedApp;
    if (app == null) {
      return;
    }
    if (!await _ensureRoot()) {
      await _showRootRequiredDialog();
      return;
    }

    final newId = _newIdController.text.trim();
    if (!RegExp(r'^[0-9a-fA-F]{16}$').hasMatch(newId)) {
      setState(() {
        _statusMessage = 'Device ID must be 16 hex characters (0-9, a-f).';
      });
      return;
    }

    setState(() {
      _updatingSsaid = true;
      _statusMessage = 'Updating SSAID for ${app.name}...';
    });

    try {
      final output = await RootPlus.executeRootCommand(
        _buildUpdateCommand(app.packageName, newId),
      );
      if (!mounted) {
        return;
      }

      if (output.contains('ABX_MISSING')) {
        setState(() {
          _updatingSsaid = false;
          _statusMessage =
              'ABX tools are required on Android 12+ (abx2xml/xml2abx).';
        });
        return;
      }

      if (output.contains('ABX_WRITE_MISSING')) {
        setState(() {
          _updatingSsaid = false;
          _statusMessage =
              'xml2abx is missing. Install it to write Android 12+ SSAIDs.';
        });
        return;
      }

      if (output.contains('ABX_WRITE_FAILED')) {
        setState(() {
          _updatingSsaid = false;
          _statusMessage =
              'Failed to convert XML back to ABX. Update not applied.';
        });
        return;
      }

      if (output.contains('NO_ENTRY')) {
        setState(() {
          _updatingSsaid = false;
          _statusMessage =
              'SSAID entry missing. Launch the app once and try again.';
        });
        return;
      }

      setState(() {
        _updatingSsaid = false;
        _currentSsaid = newId;
        _statusMessage = 'SSAID updated. Restart the device to pick it up.';
      });
      await _promptRestartDevice(app);
    } on RootCommandException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _updatingSsaid = false;
        _statusMessage = 'Root command failed: ${e.message}';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _updatingSsaid = false;
        _statusMessage = 'Failed to update SSAID: $e';
      });
    }
  }

  Future<void> _promptRestartDevice(AppInfo app) async {
    if (!mounted) {
      return;
    }
    final shouldRestart = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: AppColors.surfaceAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Restart phone now?'),
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          content: Text(
            'The new SSAID for ${app.name} may not apply until the device restarts.',
          ),
          contentTextStyle: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restart'),
            ),
          ],
        );
      },
    );

    if (shouldRestart != true) {
      return;
    }
    if (!await _ensureRoot()) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage = 'Restarting device...';
    });

    try {
      await RootPlus.executeRootCommand('reboot');
    } on RootCommandException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Restart failed: ${e.message}';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Restart failed: $e';
      });
    }
  }

  Future<bool> _ensureRoot() async {
    if (_rootReady) {
      return true;
    }
    if (!_rootChecked) {
      await _requestRoot();
      return _rootReady;
    }
    setState(() {
      _statusMessage = 'Root access is required to run these commands.';
    });
    return false;
  }

  Future<void> _showRootRequiredDialog() async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: AppColors.surfaceAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Root required'),
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          content: const Text(
            'Root access is required to update SSAID entries.',
          ),
          contentTextStyle: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _buildReadCommand(String packageName) {
    const template = r'''
          IN=/data/system/users/0/settings_ssaid.xml
          TMP=/data/local/tmp/ssaid_query.xml
          PKG=__PKG__
          ABX_MODE=0

          if command -v abx2xml >/dev/null 2>&1; then
            if abx2xml "$IN" "$TMP" >/dev/null 2>&1; then
              ABX_MODE=1
            else
              cat "$IN" > "$TMP"
            fi
          else
            cat "$IN" > "$TMP"
          fi

          if [ "$ABX_MODE" -eq 0 ]; then
            if ! head -c 200 "$TMP" | tr -d "\0" | grep -q "<"; then
              echo "ABX_MISSING"
              exit 3
            fi
          fi

          grep -n -F "package=\"$PKG\"" "$TMP" || true
          ''';
    return template.replaceAll('__PKG__', _shellQuote(packageName));
  }

  String _buildUpdateCommand(String packageName, String newId) {
    const template = r'''
          IN=/data/system/users/0/settings_ssaid.xml
          TMP=/data/local/tmp/settings_ssaid.xml
          PKG=__PKG__
          VAL=__VAL__
          ABX_MODE=0

          if command -v abx2xml >/dev/null 2>&1; then
            if abx2xml "$IN" "$TMP" >/dev/null 2>&1; then
              ABX_MODE=1
            else
              cat "$IN" > "$TMP"
            fi
          else
            cat "$IN" > "$TMP"
          fi

          if [ "$ABX_MODE" -eq 0 ]; then
            if ! head -c 200 "$TMP" | tr -d "\0" | grep -q "<"; then
              echo "ABX_MISSING"
              exit 3
            fi
          fi

          if grep -q -F "package=\"$PKG\"" "$TMP"; then
            awk -v pkg="$PKG" -v val="$VAL" '
              index($0, "package=\"" pkg "\"") {
                gsub(/value="[^"]*"/, "value=\"" val "\"")
                gsub(/defaultValue="[^"]*"/, "defaultValue=\"" val "\"")
              }
              { print }
            ' "$TMP" > "$TMP.new" && mv "$TMP.new" "$TMP"
          else
            echo "NO_ENTRY"
            exit 2
          fi

          if [ "$ABX_MODE" -eq 1 ]; then
            if command -v xml2abx >/dev/null 2>&1; then
              if xml2abx "$TMP" "$IN" >/dev/null 2>&1; then
                :
              else
                echo "ABX_WRITE_FAILED"
                exit 4
              fi
            else
              echo "ABX_WRITE_MISSING"
              exit 4
            fi
          else
            cat "$TMP" > "$IN"
          fi

          chown system:system "$IN" 2>/dev/null || true
          chmod 600 "$IN" 2>/dev/null || true
          restorecon "$IN" 2>/dev/null || true
          sync

          echo "OK"
          ''';
    return template
        .replaceAll('__PKG__', _shellQuote(packageName))
        .replaceAll('__VAL__', _shellQuote(newId));
  }

  String _shellQuote(String value) {
    final escaped = value.replaceAll("'", "'\\''");
    return "'$escaped'";
  }

  String? _extractSsaid(String output) {
    for (final line in output.split('\n')) {
      if (!line.contains('package=')) {
        continue;
      }
      final valueMatch = RegExp(r'value="([^"]+)"').firstMatch(line);
      if (valueMatch != null) {
        return valueMatch.group(1);
      }
      final defaultMatch = RegExp(r'defaultValue="([^"]+)"').firstMatch(line);
      if (defaultMatch != null) {
        return defaultMatch.group(1);
      }
    }
    return null;
  }

  String _generateRandomSsaid() {
    const chars = '0123456789abcdef';
    final rand = Random.secure();
    return List<String>.generate(
      16,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Color _applyOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _rootReady ? AppColors.accent : const Color(0xFFE66A6A);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SsaidLogo(size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SSAID Changer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadingApps ? null : _loadApps,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh apps',
                  ),
                ],
              ),
              Text(
                'Rooted SSAID editor',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _applyOpacity(statusColor, 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _applyOpacity(statusColor, 0.35),
                      ),
                    ),
                    child: Text(
                      _rootReady ? 'ROOT OK' : 'ROOT REQUIRED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (_rootChecked && !_rootReady) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _applyOpacity(const Color(0xFFE66A6A), 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _applyOpacity(const Color(0xFFE66A6A), 0.35),
                        ),
                      ),
                      child: Text(
                        'ACCESS DENIED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFE66A6A),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _requestRoot,
                    style: TextButton.styleFrom(
                      textStyle: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildAppDropdown(theme),
              const SizedBox(height: 8),
              _buildSelectedPanel(theme),
              const Spacer(),
              Center(child: _buildStatusBanner(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme) {
    final message = _statusMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
      ),
    );
  }

  Widget _buildAppDropdown(ThemeData theme) {
    if (_loadingApps) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_apps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No apps found.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
      );
    }

    final labelText = _selectedApp?.name ?? 'Select an app';
    final labelColor =
        _selectedApp == null ? AppColors.mutedText : AppColors.text;

    return InkWell(
      onTap: _openAppPicker,
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: InputDecoration(
          suffixText: '${_apps.length} apps',
          suffixStyle: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.mutedText,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                labelText,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: labelColor),
              ),
            ),
            const Icon(Icons.expand_more, size: 18, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppPicker() async {
    if (_loadingApps || _apps.isEmpty) {
      return;
    }

    final selected = await showModalBottomSheet<AppInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        String query = '';
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: DefaultTabController(
            length: 3,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final theme = Theme.of(context);
                final userApps = _apps
                    .where((app) => !app.isSystemApp)
                    .toList();
                final systemApps = _apps
                    .where((app) => app.isSystemApp)
                    .toList();
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          width: 40,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select app',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          autofocus: true,
                          onChanged: (value) {
                            setSheetState(() {
                              query = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search apps',
                            prefixIcon: Icon(Icons.search, size: 18),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TabBar(
                          labelColor: AppColors.accent,
                          unselectedLabelColor: AppColors.mutedText,
                          indicatorColor: AppColors.accent,
                          tabs: const [
                            Tab(text: 'User apps'),
                            Tab(text: 'System apps'),
                            Tab(text: 'All apps'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildAppList(context, theme, userApps, query),
                              _buildAppList(context, theme, systemApps, query),
                              _buildAppList(context, theme, _apps, query),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await _selectApp(selected);
    }
  }

  Widget _buildAppList(
    BuildContext context,
    ThemeData theme,
    List<AppInfo> apps,
    String query,
  ) {
    final filteredApps = _filterApps(apps, query);
    if (filteredApps.isEmpty) {
      return Center(
        child: Text(
          'No matching apps.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredApps.length,
      separatorBuilder: (_, index) => const Divider(),
      itemBuilder: (context, index) {
        final app = filteredApps[index];
        return ListTile(
          onTap: () => Navigator.pop(context, app),
          leading: _buildAppIcon(theme, app),
          title: Text(
            app.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            app.packageName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          trailing: _selectedApp?.packageName == app.packageName
              ? const Icon(Icons.check, color: AppColors.accent, size: 18)
              : null,
        );
      },
    );
  }

  Widget _buildAppIcon(ThemeData theme, AppInfo app) {
    final icon = app.icon;
    if (icon == null || icon.isEmpty) {
      return _buildAppFallback(theme, app.name);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.memory(
        icon,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAppFallback(theme, app.name),
      ),
    );
  }

  Widget _buildAppFallback(ThemeData theme, String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        initial,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSelectedPanel(ThemeData theme) {
    final app = _selectedApp;
    if (app == null) {
      return InkWell(
        onTap: _openAppPicker,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.app_shortcut,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pick an app',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspect its SSAID entry',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            app.packageName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current SSAID',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              if (_loadingSsaid)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            _currentSsaid ?? 'Not loaded',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _newIdController,
                  maxLength: 16,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'New SSAID (16 hex chars)',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loadingSsaid ? null : _fetchSsaid,
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Refresh SSAID'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _newIdController.text = _generateRandomSsaid();
                          });
                        },
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: const Text('Randomize'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updatingSsaid ? null : _updateSsaid,
                    icon: _updatingSsaid
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_reset, size: 18),
                    label: const Text('Update SSAID'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:root_plus/root_plus.dart';

const _accentColor = Color(0xFF4DD6C3);
const _backgroundColor = Color(0xFF0F1114);
const _surfaceColor = Color(0xFF171A1F);
const _surfaceAltColor = Color(0xFF1E2228);
const _borderColor = Color(0xFF2A2F36);
const _textColor = Color(0xFFE7ECEF);
const _mutedTextColor = Color(0xFFA9B1BA);

void main() {
  runApp(const DeviceIdApp());
}

class DeviceIdApp extends StatelessWidget {
  const DeviceIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    final theme = base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: Brightness.dark,
        surface: _surfaceColor,
      ),
      scaffoldBackgroundColor: _backgroundColor,
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: _textColor,
        displayColor: _textColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: _surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _accentColor),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      dividerTheme: const DividerThemeData(
        color: _borderColor,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(vertical: 10),
          backgroundColor: _accentColor,
          foregroundColor: _backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(vertical: 10),
          foregroundColor: _accentColor,
          side: const BorderSide(color: _accentColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          foregroundColor: _accentColor,
        ),
      ),
    );

    return MaterialApp(
      title: 'SSAID Changer',
      theme: theme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _animate = true;
      });
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DeviceIdHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: _animate ? 1 : 0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 420),
            scale: _animate ? 1 : 0.94,
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SsaidLogo(size: 88),
                const SizedBox(height: 16),
                Text(
                  'SSAID Changer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rooted device ID editor',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SsaidLogo extends StatelessWidget {
  const SsaidLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo.svg',
      width: size,
      height: size,
    );
  }
}

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
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      final filtered = apps.where((app) => !app.isSystemApp).toList();
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

  List<AppInfo> _filterApps(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _apps;
    }
    return _apps.where((app) {
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
        _statusMessage = 'SSAID updated. Restart the app to pick it up.';
      });
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
    final statusColor =
        _rootReady ? _accentColor : const Color(0xFFE66A6A);

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
                  color: _mutedTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _applyOpacity(statusColor, 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _applyOpacity(statusColor, 0.35),
                      ),
                    ),
                    child: Text(
                      _rootReady ? 'ROOT OK' : 'ROOT REQUIRED',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
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
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFFE66A6A),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _requestRoot,
                    child: const Text('Retry'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusBanner(theme),
              const SizedBox(height: 8),
              _buildAppDropdown(theme),
              const SizedBox(height: 8),
              _buildSelectedPanel(theme),
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
        color: _surfaceAltColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: _mutedTextColor,
        ),
      ),
    );
  }

  Widget _buildAppDropdown(ThemeData theme) {
    if (_loadingApps) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _borderColor),
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
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _borderColor),
        ),
        child: Text(
          'No user-installed apps found.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _mutedTextColor,
          ),
        ),
      );
    }

    final labelText = _selectedApp?.name ?? 'Select an app';
    final labelColor = _selectedApp == null ? _mutedTextColor : _textColor;

    return InkWell(
      onTap: _openAppPicker,
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: InputDecoration(
          suffixText: '${_apps.length} apps',
          suffixStyle: theme.textTheme.labelSmall?.copyWith(
            color: _mutedTextColor,
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
            const Icon(Icons.expand_more, size: 18, color: _mutedTextColor),
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
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredApps = _filterApps(query);
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
                        color: _borderColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select app',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _textColor,
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
                    Expanded(
                      child: filteredApps.isEmpty
                          ? Center(
                              child: Text(
                                'No matching apps.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: _mutedTextColor),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredApps.length,
                              separatorBuilder: (_, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final app = filteredApps[index];
                                return ListTile(
                                  onTap: () => Navigator.pop(context, app),
                                  title: Text(
                                    app.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: _textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  subtitle: Text(
                                    app.packageName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: _mutedTextColor),
                                  ),
                                  trailing: _selectedApp?.packageName ==
                                          app.packageName
                                      ? const Icon(
                                          Icons.check,
                                          color: _accentColor,
                                          size: 18,
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      await _selectApp(selected);
    }
  }

  Widget _buildSelectedPanel(ThemeData theme) {
    final app = _selectedApp;
    if (app == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _borderColor),
        ),
        child: Text(
          'Pick an app to inspect its SSAID entry.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _mutedTextColor,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            app.packageName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _mutedTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current SSAID',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _mutedTextColor,
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
              color: _accentColor,
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
                    fillColor: _surfaceAltColor,
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

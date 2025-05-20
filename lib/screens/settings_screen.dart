import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/widgets/app_scaffold.dart';
import 'package:cupsy/services/analytics_service.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 테마 모드를 관리하는 프로바이더
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// 앱 설정 화면
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _analyticsEnabled = true;
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSaveEnabled = true;
  String _appVersion = '';
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 분석 설정 로드
      _analyticsEnabled = AnalyticsService.instance.isEnabled;

      // SharedPreferences에서 설정 로드
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _autoSaveEnabled = prefs.getBool('auto_save_enabled') ?? true;

      // 테마 설정 로드
      final themeSetting = prefs.getString('theme_mode') ?? 'system';
      switch (themeSetting) {
        case 'light':
          ref.read(themeProvider.notifier).state = ThemeMode.light;
          break;
        case 'dark':
          ref.read(themeProvider.notifier).state = ThemeMode.dark;
          break;
        default:
          ref.read(themeProvider.notifier).state = ThemeMode.system;
      }

      // 앱 버전 정보 로드
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';

      // 화면 방문 로깅
      await AnalyticsService.instance.logScreenView(screenName: 'Settings');

      // 애니메이션 시작
      _animationController.forward();
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '설정 로드 중 오류가 발생했습니다',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAnalytics(bool value) async {
    try {
      await AnalyticsService.instance.setAnalyticsEnabled(value);

      setState(() {
        _analyticsEnabled = value;
      });

      // 이벤트 로깅 (옵션이 켜져 있을 때만)
      if (value) {
        await AnalyticsService.instance.logEvent(
          name: 'settings_changed',
          parameters: {'analytics_enabled': value},
        );
      }
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '분석 설정 변경 중 오류가 발생했습니다',
        error: e,
        stackTrace: stackTrace,
      );

      _showErrorSnackBar(e);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);

      setState(() {
        _notificationsEnabled = value;
      });

      // 이벤트 로깅
      await AnalyticsService.instance.logEvent(
        name: 'settings_changed',
        parameters: {'notifications_enabled': value},
      );
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '알림 설정 변경 중 오류가 발생했습니다',
        error: e,
        stackTrace: stackTrace,
      );

      _showErrorSnackBar(e);
    }
  }

  Future<void> _toggleVibration(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vibration_enabled', value);

      setState(() {
        _vibrationEnabled = value;
      });

      // 햅틱 피드백 데모
      if (value) {
        HapticFeedback.mediumImpact();
      }

      // 이벤트 로깅
      await AnalyticsService.instance.logEvent(
        name: 'settings_changed',
        parameters: {'vibration_enabled': value},
      );
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '진동 설정 변경 중 오류가 발생했습니다',
        error: e,
        stackTrace: stackTrace,
      );

      _showErrorSnackBar(e);
    }
  }

  Future<void> _toggleAutoSave(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_save_enabled', value);

      setState(() {
        _autoSaveEnabled = value;
      });

      // 이벤트 로깅
      await AnalyticsService.instance.logEvent(
        name: 'settings_changed',
        parameters: {'auto_save_enabled': value},
      );
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '자동 저장 설정 변경 중 오류가 발생했습니다',
        error: e,
        stackTrace: stackTrace,
      );

      _showErrorSnackBar(e);
    }
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeSetting;

      switch (mode) {
        case ThemeMode.light:
          themeSetting = 'light';
          break;
        case ThemeMode.dark:
          themeSetting = 'dark';
          break;
        default:
          themeSetting = 'system';
      }

      await prefs.setString('theme_mode', themeSetting);
      ref.read(themeProvider.notifier).state = mode;

      // 이벤트 로깅
      await AnalyticsService.instance.logEvent(
        name: 'settings_changed',
        parameters: {'theme_mode': themeSetting},
      );
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '테마 설정 변경 중 오류가 발생했습니다',
        error: e,
        stackTrace: stackTrace,
      );

      _showErrorSnackBar(e);
    }
  }

  Future<void> _resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 컬렉션 데이터 초기화 확인 대화상자
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('모든 데이터 초기화'),
              content: const Text(
                '정말로 모든 앱 데이터를 초기화하시겠습니까?\n'
                '컬렉션, 획득한 컵, 기록된 감정 등 모든 데이터가 삭제됩니다.\n\n'
                '이 작업은 되돌릴 수 없습니다.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('초기화'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // SharedPreferences 데이터 초기화
      // 설정값은 유지하고 앱 데이터만 초기화
      await prefs.remove('collected_cups');
      await prefs.remove('emotional_records');
      await prefs.remove('last_created_date');
      await prefs.remove('daily_creation_count');
      await prefs.remove('unlocked_designs');

      // 초기화 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 데이터가 초기화되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 이벤트 로깅
      await AnalyticsService.instance.logEvent(name: 'reset_all_data');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '데이터 초기화 중 오류가 발생했습니다',
        error: e,
        stackTrace: stackTrace,
      );

      _showErrorSnackBar(e);
    }
  }

  void _showErrorSnackBar(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandlingService.getUserFriendlyErrorMessage(error),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return AppScaffold(
      title: '설정',
      showBackButton: true,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 일반 설정 섹션
                    _buildSectionHeader('일반'),
                    _buildSettingItem(
                      icon: Icons.analytics_outlined,
                      title: '데이터 분석 허용',
                      description: '사용자 경험 개선을 위한 익명 데이터 수집을 허용합니다.',
                      trailing: Switch(
                        value: _analyticsEnabled,
                        onChanged: _toggleAnalytics,
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.notifications_outlined,
                      title: '알림 허용',
                      description: '일일 감정 기록 알림을 허용합니다.',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.vibration,
                      title: '진동 피드백',
                      description: '버튼이나 액션 시 촉각적 피드백을 제공합니다.',
                      trailing: Switch(
                        value: _vibrationEnabled,
                        onChanged: _toggleVibration,
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.save_outlined,
                      title: '자동 저장',
                      description: '컵 생성 결과를 자동으로 저장합니다.',
                      trailing: Switch(
                        value: _autoSaveEnabled,
                        onChanged: _toggleAutoSave,
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.dark_mode_outlined,
                      title: '테마 설정',
                      description: '앱의 화면 테마를 설정합니다.',
                      trailing: DropdownButton<ThemeMode>(
                        value: themeMode,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text(
                              '시스템 설정',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text(
                              '라이트 모드',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text(
                              '다크 모드',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _changeThemeMode(value);
                          }
                        },
                      ),
                    ),
                    const Divider(),

                    // 계정 섹션 (향후 구현)
                    _buildSectionHeader('계정'),
                    _buildSettingItem(
                      icon: Icons.account_circle_outlined,
                      title: '계정 관리',
                      description: '계정 정보 관리 및 설정',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 계정 관리 화면으로 이동 (향후 구현)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('계정 관리 기능은 아직 구현되지 않았습니다.'),
                          ),
                        );
                      },
                    ),
                    const Divider(),

                    // 데이터 관리 섹션
                    _buildSectionHeader('데이터 관리'),
                    _buildSettingItem(
                      icon: Icons.delete_outline,
                      title: '데이터 초기화',
                      description: '모든 컬렉션 및 기록을 초기화합니다.',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _resetAllData,
                    ),
                    const Divider(),

                    // 정보 섹션
                    _buildSectionHeader('정보'),
                    _buildSettingItem(
                      icon: Icons.info_outline,
                      title: '앱 정보',
                      description: '버전: $_appVersion',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 앱 정보 화면으로 이동 (향후 구현)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('앱 정보 화면은 아직 구현되지 않았습니다.'),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.policy_outlined,
                      title: '개인정보 처리방침',
                      description: '개인정보 수집 및 이용에 관한 안내',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 개인정보 처리방침 화면으로 이동 (향후 구현)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('개인정보 처리방침 화면은 아직 구현되지 않았습니다.'),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.description_outlined,
                      title: '이용약관',
                      description: '서비스 이용에 관한 약관',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 이용약관 화면으로 이동 (향후 구현)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이용약관 화면은 아직 구현되지 않았습니다.'),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.source_outlined,
                      title: '오픈소스 라이선스',
                      description: '사용된 오픈소스 라이브러리 정보',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // LicensePage 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const LicensePage(
                                  applicationName: 'Cupsy',
                                  applicationVersion: null, // 이미 저장된 버전 사용
                                ),
                          ),
                        );
                      },
                    ),
                    const Divider(),

                    // 피드백 섹션
                    _buildSectionHeader('피드백'),
                    _buildSettingItem(
                      icon: Icons.feedback_outlined,
                      title: '지원 및 피드백',
                      description: '문제 보고 또는 제안 사항',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 지원 및 피드백 화면으로 이동 (향후 구현)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('지원 및 피드백 기능은 아직 구현되지 않았습니다.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  /// 섹션 헤더 위젯 생성
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  /// 설정 항목 위젯 생성
  Widget _buildSettingItem({
    required String title,
    required String description,
    required Widget trailing,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading:
          icon != null
              ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              )
              : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

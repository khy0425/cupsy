import 'package:flutter/material.dart';
import 'package:cupsy/theme/app_theme.dart';

/// 앱 전체에서 일관된 스캐폴드 UI를 제공하는 위젯입니다.
/// 모든 화면에서 동일한 구조를 유지하고 테마를 적용하기 위해 사용합니다.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final PreferredSizeWidget? customAppBar;
  final VoidCallback? onBackPressed;

  /// AppScaffold 생성자
  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.showBackButton = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
    this.customAppBar,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.backgroundColor,
      appBar: customAppBar ?? _buildAppBar(context),
      body: SafeArea(child: Padding(padding: padding, child: body)),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  /// 기본 AppBar를 생성합니다.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
              : null,
      actions: actions,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/backend_sync.dart';

/// 5-tab bottom nav: Home · Teams · Players · Tourneys · Profile.
class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    // Load all public data once when the shell mounts.
    // Individual screens listen to AppStore and rebuild automatically.
    BackendSync.instance.refreshAll().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => _HomeShellView(child: widget.child);
}

class _HomeShellView extends StatelessWidget {
  final Widget child;
  const _HomeShellView({required this.child});

  static const _tabs = [
    _Tab('/home', Icons.home_rounded, Icons.home_outlined, 'Home'),
    _Tab('/teams', Icons.groups_rounded, Icons.groups_outlined, 'Teams'),
    _Tab('/players', Icons.person_rounded, Icons.person_outline, 'Players'),
    _Tab('/tournaments', Icons.emoji_events_rounded,
        Icons.emoji_events_outlined, 'Tourneys'),
    _Tab('/profile', Icons.account_circle_rounded,
        Icons.account_circle_outlined, 'Profile'),
  ];

  int _indexOf(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selected = _indexOf(location);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final isSel = i == selected;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(t.path),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSel ? t.iconFilled : t.iconOutlined,
                                size: 20,
                                color:
                                    isSel ? AppColors.goldDeep : AppColors.grey,
                              ),
                              if (isSel)
                                Positioned(
                                  top: -8,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.label.toUpperCase(),
                            style: AppTextStyles.mono(
                              size: 8,
                              letterSpacing: 0.1,
                              color:
                                  isSel ? AppColors.goldDeep : AppColors.grey,
                              weight: isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData iconFilled;
  final IconData iconOutlined;
  final String label;
  const _Tab(this.path, this.iconFilled, this.iconOutlined, this.label);
}

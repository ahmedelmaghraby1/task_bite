import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/routes/routes.dart';
import 'package:taskbite/features/home/data/constant_data.dart';
import 'package:taskbite/features/home/presentation/widgets/custom_bottom_navigation_bar.dart';
import 'package:taskbite/features/tasks/domain/task_workflow.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_state.dart';
import 'package:taskbite/features/tasks/presentation/widgets/overview_stats.dart';
import 'package:taskbite/features/tasks/presentation/widgets/primary_action_bar.dart';

/// The dashboard: brand header, live overview stats, a single shared search
/// field and the status tabs. The primary create actions (voice / type) are
/// docked above the bottom navigation, but only while the New tab is selected
/// so tasks can only be created from there.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // A deadline may have passed while the app was backgrounded or closed;
      // re-evaluate so the Failed list and the counters are correct.
      context.read<TasksCubit>().onAppResumed();
    }
  }

  @override
  bool get wantKeepAlive => true;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    if ((_selectedIndex - index).abs() > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) => setState(() => _selectedIndex = index);

  String get _greetingKey {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'greetingMorning';
    if (hour < 17) return 'greetingAfternoon';
    return 'greetingEvening';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Creation is only offered from the New tab. The gate is the same
            // TaskCreationPolicy the list empty states use, so the rule is
            // enforced in one place rather than by hide-and-hope.
            if (TaskCreationPolicy.canCreateFrom(
              taskTabs[_selectedIndex].status,
            ))
              const PrimaryActionBar(),
            CustomBottomNavigationBar(
              index: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              greetingKey: _greetingKey,
              onSettings:
                  () => Navigator.pushNamed(context, AppRoutes.settingsScreen),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 0),
              child: BlocBuilder<TasksCubit, TasksState>(
                builder: (context, state) => OverviewStats(state: state),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: _SearchField(
                onChanged: (value) => context.read<TasksCubit>().search(value),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) => pages[index],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greetingKey, required this.onSettings});

  final String greetingKey;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingKey.tr(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'appName'.tr(context),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'settings'.tr(context),
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.isNotEmpty;
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'search'.tr(context),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon:
            hasText
                ? IconButton(
                  tooltip: 'clearSearch'.tr(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
                : null,
        filled: true,
        fillColor: scheme.surface,
      ),
    );
  }
}

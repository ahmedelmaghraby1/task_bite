import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/routes/routes.dart';
import 'package:taskbite/features/home/data/constant_data.dart';
import 'package:taskbite/features/home/presentation/widgets/custom_bottom_navigation_bar.dart';
import 'package:taskbite/features/tasks/presentation/widgets/custom_modal_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  late final PageController _pageController;
  @override
  void initState() {
    _pageController = PageController();
    super.initState();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    if ((_selectedIndex - index).abs() > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.linear,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsetsDirectional.only(end: 10.w, bottom: 30.h),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              isScrollControlled: true,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              context: context,
              builder: (context) => CustomModalBottomSheet(),
            );
          },
          child: CircleAvatar(
            radius: 26,
            child: Icon(Icons.add_outlined, size: 40),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        index: _selectedIndex,
        onTap: _onItemTapped,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 20.w, top: 50.h),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.settingsScreen);
                },
                child: Icon(Icons.settings),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => pages[index],
              controller: _pageController,
            ),
          ),
        ],
      ),
    );
  }
}

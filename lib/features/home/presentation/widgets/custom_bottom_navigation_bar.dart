import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/features/home/data/constant_data.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int index;
  final void Function(int) onTap;
  const CustomBottomNavigationBar({
    super.key,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusDirectional.only(
        topStart: Radius.circular(10.r),
        topEnd: Radius.circular(10.r),
      ),

      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
        ),
        height: 90.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (currentIndex) => Expanded(
              child: InkWell(
                onTap: () {
                  onTap(currentIndex);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.bounceInOut,
                  decoration: BoxDecoration(
                    color:
                        currentIndex == index
                            ? AppColors.white
                            : AppColors.transparent,
                    gradient: LinearGradient(
                      colors: [AppColors.purpple, AppColors.lightPurpple],
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        navItemsIcons[currentIndex],
                        color: currentIndex == index ? AppColors.white : null,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        navItemsNames[currentIndex].tr(context),
                        style: TextStyle(
                          color: currentIndex == index ? AppColors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

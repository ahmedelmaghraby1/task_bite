import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/constants/images.dart';
import 'package:taskbite/core/routes/routes.dart';
import 'package:taskbite/core/themes/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool firstWord = false;
  bool secondWord = false;
  bool viewImage = false;

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        firstWord = true;
      });
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        secondWord = true;
      });
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        viewImage = true;
      });
    });
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (!mounted) {
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.purpple, AppColors.lightPurpple],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10.h,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10.w,
                children: [
                  AnimatedOpacity(
                    opacity: firstWord ? 1 : 0,
                    duration: const Duration(seconds: 1),
                    child: Text(
                      'Task',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontSize: 30,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: secondWord ? 1 : 0,
                    duration: const Duration(seconds: 1),
                    child: Text(
                      'bite',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontSize: 20,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 120.h,
                child:
                    viewImage
                        ? TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.5, end: 1.0),
                          duration: Duration(seconds: 2),
                          curve: Curves.elasticInOut,
                          builder:
                              (context, value, child) =>
                                  Transform.scale(scale: value, child: child),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 10,
                            children: [Image.asset(ImageConstants.task)],
                          ),
                        )
                        : SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

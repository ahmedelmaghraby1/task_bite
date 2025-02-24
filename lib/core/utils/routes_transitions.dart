// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class CustomSlideNavigation extends PageRouteBuilder {
  final Widget page;
  CustomSlideNavigation({
    required this.page,
  }) : super(
            pageBuilder: (context, animation, animationTwo) => page,
            transitionsBuilder: (context, animation, animationTwo, child) {
              //these to for slide transition
              Animation<Offset> offsetAnimation = animation.drive(Tween(
                  begin: const Offset(1.0, 0.0), end: const Offset(0.0, 0.0)));
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            });
}

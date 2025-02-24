import 'package:flutter/material.dart';

class HeadTitle extends StatelessWidget {
  final String title;
  const HeadTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Text(title, style: Theme.of(context).textTheme.titleLarge!)],
    );
  }
}

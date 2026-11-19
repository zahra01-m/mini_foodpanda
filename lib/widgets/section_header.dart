import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.redBright, p.red]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

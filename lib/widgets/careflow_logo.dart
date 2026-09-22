import 'package:flutter/material.dart';

class CareFlowLogo extends StatelessWidget {
  const CareFlowLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 48,
        weight: 900,
      ),
    );
  }
}

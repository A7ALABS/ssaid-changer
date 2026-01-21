import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SsaidLogo extends StatelessWidget {
  const SsaidLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo.svg',
      width: size,
      height: size,
    );
  }
}

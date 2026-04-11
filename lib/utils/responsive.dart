import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;

  Responsive(this.context);

  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Device type getters
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;

  // Screen dimensions
  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  // Responsive sizing
  double wp(double percentage) => width * percentage / 100;
  double hp(double percentage) => height * percentage / 100;

  // Responsive font sizes
  double get smallText => isMobile ? 12 : (isTablet ? 14 : 16);
  double get normalText => isMobile ? 14 : (isTablet ? 16 : 18);
  double get mediumText => isMobile ? 16 : (isTablet ? 18 : 20);
  double get largeText => isMobile ? 20 : (isTablet ? 24 : 28);
  double get extraLargeText => isMobile ? 24 : (isTablet ? 28 : 32);

  // Responsive padding
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
        vertical: isMobile ? 16 : (isTablet ? 20 : 24),
      );

  EdgeInsets get cardPadding => EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 20));

  // Responsive spacing
  double get smallSpacing => isMobile ? 8 : (isTablet ? 10 : 12);
  double get normalSpacing => isMobile ? 12 : (isTablet ? 16 : 20);
  double get largeSpacing => isMobile ? 16 : (isTablet ? 24 : 32);

  // Responsive icon sizes
  double get smallIcon => isMobile ? 16 : (isTablet ? 20 : 24);
  double get normalIcon => isMobile ? 24 : (isTablet ? 28 : 32);
  double get largeIcon => isMobile ? 32 : (isTablet ? 40 : 48);

  // Responsive border radius
  double get smallRadius => isMobile ? 8 : (isTablet ? 10 : 12);
  double get normalRadius => isMobile ? 12 : (isTablet ? 14 : 16);
  double get largeRadius => isMobile ? 16 : (isTablet ? 20 : 24);

  // Grid columns
  int get gridColumns => isMobile ? 2 : (isTablet ? 3 : 4);

  // Card aspect ratio
  double get cardAspectRatio => isMobile ? 1.2 : (isTablet ? 1.3 : 1.4);
}

// Extension for easier access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}

// Responsive Layout Builder
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Responsive.mobileBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

// Adaptive Widget - changes based on platform
class AdaptiveWidget extends StatelessWidget {
  final Widget android;
  final Widget? ios;

  const AdaptiveWidget({
    super.key,
    required this.android,
    this.ios,
  });

  @override
  Widget build(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? (ios ?? android)
        : android;
  }
}
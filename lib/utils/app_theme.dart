// // lib/utils/app_theme.dart
// import 'package:flutter/material.dart';

// class AppTheme {
//   // Light Theme Colors
//   static const Color lightPrimary = Color(0xFF6C63FF);
//   static const Color lightSecondary = Color(0xFF00D4FF);
//   static const Color lightAccent = Color(0xFFFF6B9D);
//   static const Color lightBackground = Color(0xFFF8F9FF);
//   static const Color lightSurface = Colors.white;
//   static const Color lightError = Color(0xFFFF5252);
//   static const Color lightSuccess = Color(0xFF1DD1A1);
  
//   // Dark Theme Colors
//   static const Color darkPrimary = Color(0xFF8B7FFF);
//   static const Color darkSecondary = Color(0xFF00E5FF);
//   static const Color darkAccent = Color(0xFFFF7BAD);
//   static const Color darkBackground = Color(0xFF0F0F1E);
//   static const Color darkSurface = Color(0xFF1F1F2E);
//   static const Color darkError = Color(0xFFFF6B6B);
//   static const Color darkSuccess = Color(0xFF2EE1B1);

//   // Gradient Definitions
//   static const LinearGradient lightPrimaryGradient = LinearGradient(
//     colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   static const LinearGradient darkPrimaryGradient = LinearGradient(
//     colors: [Color(0xFF8B7FFF), Color(0xFF00E5FF)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   static const LinearGradient accentGradient = LinearGradient(
//     colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   static const LinearGradient successGradient = LinearGradient(
//     colors: [Color(0xFF1DD1A1), Color(0xFF10AC84)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   // Text Styles
//   static TextTheme lightTextTheme = const TextTheme(
//     displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
//     displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
//     displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
//     headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
//     headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
//     titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2D3142)),
//     bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF2D3142)),
//     bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
//   );

//   static TextTheme darkTextTheme = const TextTheme(
//     displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
//     displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
//     displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
//     headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
//     headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
//     titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
//     bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
//     bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB0B0C0)),
//   );

//   // Light Theme
//   static ThemeData lightTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,
//     primaryColor: lightPrimary,
//     scaffoldBackgroundColor: lightBackground,
//     colorScheme: const ColorScheme.light(
//       primary: lightPrimary,
//       secondary: lightSecondary,
//       surface: lightSurface,
//       background: lightBackground,
//       error: lightError,
//     ),
//     textTheme: lightTextTheme,
//     appBarTheme: const AppBarTheme(
//       elevation: 0,
//       backgroundColor: lightPrimary,
//       foregroundColor: Colors.white,
//       centerTitle: true,
//     ),
//     cardTheme: CardTheme(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       color: lightSurface,
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         elevation: 0,
//         backgroundColor: lightPrimary,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: lightSurface,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: BorderSide.none,
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: const BorderSide(color: lightPrimary, width: 2),
//       ),
//     ),
//   );

//   // Dark Theme
//   static ThemeData darkTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,
//     primaryColor: darkPrimary,
//     scaffoldBackgroundColor: darkBackground,
//     colorScheme: const ColorScheme.dark(
//       primary: darkPrimary,
//       secondary: darkSecondary,
//       surface: darkSurface,
//       background: darkBackground,
//       error: darkError,
//     ),
//     textTheme: darkTextTheme,
//     appBarTheme: const AppBarTheme(
//       elevation: 0,
//       backgroundColor: Colors.transparent,
//       foregroundColor: Colors.white,
//       centerTitle: true,
//     ),
//     cardTheme: CardTheme(
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       color: darkSurface,
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         elevation: 0,
//         backgroundColor: darkPrimary,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: darkSurface,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: BorderSide.none,
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: const BorderSide(color: darkPrimary, width: 2),
//       ),
//     ),
//   );
// }

// // lib/utils/animations.dart
// import 'package:flutter/material.dart';

// class AnimationUtils {
//   // Slide in from bottom
//   static Widget slideInFromBottom({
//     required Widget child,
//     required AnimationController controller,
//     int delay = 0,
//   }) {
//     final animation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: controller,
//       curve: Interval(
//         delay / 1000,
//         1.0,
//         curve: Curves.easeOutCubic,
//       ),
//     ));

//     return SlideTransition(
//       position: animation,
//       child: FadeTransition(
//         opacity: controller,
//         child: child,
//       ),
//     );
//   }

//   // Scale animation
//   static Widget scaleIn({
//     required Widget child,
//     required AnimationController controller,
//     int delay = 0,
//   }) {
//     final animation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: controller,
//       curve: Interval(
//         delay / 1000,
//         1.0,
//         curve: Curves.easeOutBack,
//       ),
//     ));

//     return ScaleTransition(
//       scale: animation,
//       child: FadeTransition(
//         opacity: controller,
//         child: child,
//       ),
//     );
//   }

//   // Slide from right
//   static Widget slideFromRight({
//     required Widget child,
//     required int index,
//   }) {
//     return TweenAnimationBuilder<double>(
//       duration: Duration(milliseconds: 400 + (index * 50)),
//       tween: Tween(begin: 0.0, end: 1.0),
//       curve: Curves.easeOut,
//       builder: (context, value, _) {
//         return Transform.translate(
//           offset: Offset(50 * (1 - value), 0),
//           child: Opacity(
//             opacity: value,
//             child: child,
//           ),
//         );
//       },
//     );
//   }
// }

// // lib/widgets/gradient_button.dart
// import 'package:flutter/material.dart';

// class GradientButton extends StatefulWidget {
//   final String text;
//   final VoidCallback? onPressed;
//   final List<Color> gradientColors;
//   final IconData? icon;
//   final bool isLoading;
//   final double height;

//   const GradientButton({
//     super.key,
//     required this.text,
//     this.onPressed,
//     this.gradientColors = const [Color(0xFF6C63FF), Color(0xFF00D4FF)],
//     this.icon,
//     this.isLoading = false,
//     this.height = 56,
//   });

//   @override
//   State<GradientButton> createState() => _GradientButtonState();
// }

// class _GradientButtonState extends State<GradientButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 100),
//     );
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: _scaleAnimation,
//       child: Container(
//         height: widget.height,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(colors: widget.gradientColors),
//           boxShadow: [
//             BoxShadow(
//               color: widget.gradientColors[0].withOpacity(0.4),
//               blurRadius: 15,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: ElevatedButton(
//           onPressed: widget.isLoading
//               ? null
//               : () {
//                   _controller.forward().then((_) => _controller.reverse());
//                   widget.onPressed?.call();
//                 },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.transparent,
//             shadowColor: Colors.transparent,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//           ),
//           child: widget.isLoading
//               ? const SizedBox(
//                   height: 24,
//                   width: 24,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 )
//               : Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     if (widget.icon != null) ...[
//                       Icon(widget.icon, color: Colors.white),
//                       const SizedBox(width: 8),
//                     ],
//                     Text(
//                       widget.text,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ),
//     );
//   }
// }

// // lib/widgets/glass_card.dart
// import 'package:flutter/material.dart';
// import 'dart:ui';

// class GlassCard extends StatelessWidget {
//   final Widget child;
//   final double blur;
//   final Color? color;
//   final BorderRadius? borderRadius;
//   final EdgeInsets? padding;

//   const GlassCard({
//     super.key,
//     required this.child,
//     this.blur = 10,
//     this.color,
//     this.borderRadius,
//     this.padding,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
    
//     return ClipRRect(
//       borderRadius: borderRadius ?? BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
//         child: Container(
//           padding: padding ?? const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: color ??
//                 (isDark
//                     ? Colors.white.withOpacity(0.05)
//                     : Colors.white.withOpacity(0.7)),
//             borderRadius: borderRadius ?? BorderRadius.circular(20),
//             border: Border.all(
//               color: isDark
//                   ? Colors.white.withOpacity(0.1)
//                   : Colors.white.withOpacity(0.3),
//             ),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// // lib/widgets/shimmer_loading.dart
// import 'package:flutter/material.dart';

// class ShimmerLoading extends StatefulWidget {
//   final Widget child;
//   final bool isLoading;

//   const ShimmerLoading({
//     super.key,
//     required this.child,
//     this.isLoading = true,
//   });

//   @override
//   State<ShimmerLoading> createState() => _ShimmerLoadingState();
// }

// class _ShimmerLoadingState extends State<ShimmerLoading>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.isLoading) return widget.child;

//     final isDark = Theme.of(context).brightness == Brightness.dark;
    
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return ShaderMask(
//           shaderCallback: (bounds) {
//             return LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!,
//                 isDark ? const Color(0xFF3D3D54) : Colors.grey[100]!,
//                 isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!,
//               ],
//               stops: [
//                 _controller.value - 0.3,
//                 _controller.value,
//                 _controller.value + 0.3,
//               ],
//             ).createShader(bounds);
//           },
//           child: widget.child,
//         );
//       },
//     );
//   }
// }
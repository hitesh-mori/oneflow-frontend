import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final bool isLoading;
  final bool useGradient;
  final Color? bgColor;
  final Color? textColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.useGradient = true,
    this.bgColor,
    this.textColor,
    this.icon,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              if (!widget.isLoading) {
                _controller.forward();
                setState(() => _isPressed = true);
              }
            },
            onTapUp: (_) {
              if (!widget.isLoading) {
                _controller.reverse();
                setState(() => _isPressed = false);
              }
            },
            onTapCancel: () {
              if (!widget.isLoading) {
                _controller.reverse();
                setState(() => _isPressed = false);
              }
            },
            onTap: widget.isLoading ? null : widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: widget.useGradient && widget.bgColor == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.theme['primaryColor'],
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                color: widget.bgColor ?? (widget.useGradient ? null : AppColors.theme['primaryColor']),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (widget.bgColor ?? AppColors.theme['primaryColor'] as Color).withValues(alpha: _isPressed ? 0.25 : 0.35),
                    blurRadius: _isPressed ? 12 : 20,
                    offset: Offset(0, _isPressed ? 3 : 8),
                  ),
                  if (!_isPressed)
                    BoxShadow(
                      color: (widget.bgColor ?? AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: widget.textColor ?? Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Please wait...',
                            style: TextStyle(
                              color: widget.textColor ?? Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: widget.textColor ?? Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: widget.textColor ?? Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// File: features/authentication/presentation/widgets/social_login_button.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String provider;
  final String? icon;
  final IconData? fallbackIcon;
  final double height;
  final double? width;

  const SocialLoginButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
    required this.provider,
    this.icon,
    this.fallbackIcon,
    this.height = 56,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Connecting...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Provider Icon
                  _buildProviderIcon(),
                  
                  const SizedBox(width: 12),
                  
                  // Button Text
                  Text(
                    'Continue with $provider',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProviderIcon() {
    if (icon != null) {
      return Image.asset(
        icon!,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
      );
    }
    
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    IconData iconData;
    Color iconColor;

    switch (provider.toLowerCase()) {
      case 'google':
        iconData = fallbackIcon ?? Icons.account_circle;
        iconColor = Colors.red;
        break;
      case 'facebook':
        iconData = fallbackIcon ?? Icons.facebook;
        iconColor = Colors.blue;
        break;
      case 'apple':
        iconData = fallbackIcon ?? Icons.apple;
        iconColor = Colors.black;
        break;
      default:
        iconData = fallbackIcon ?? Icons.account_circle;
        iconColor = AppColors.primary;
    }

    return Icon(
      iconData,
      size: 24,
      color: iconColor,
    );
  }
}
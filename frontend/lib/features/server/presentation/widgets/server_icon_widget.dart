import 'package:flutter/material.dart';

class ServerIconWidget extends StatelessWidget {
  final String? iconUrl;
  final String? emojiIcon;
  final String? color;
  final double size;
  final bool isActive;
  final bool showBorder;

  const ServerIconWidget({
    super.key,
    this.iconUrl,
    this.emojiIcon,
    this.color,
    this.size = 48,
    this.isActive = false,
    this.showBorder = true,
  });

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color != null ? _parseColor(color!) : const Color(0xFF7289DA);
    final defaultIcon = emojiIcon ?? '🏠';

    Widget iconWidget;
    
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      print('ServerIconWidget: Showing image for URL: $iconUrl');
      // Show uploaded image
      iconWidget = ClipRRect(
        borderRadius: BorderRadius.circular(size / 4), // Rounded corners instead of circular
        child: Image.network(
          iconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to emoji if image fails to load
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(size / 4), // Rounded corners instead of circular
              ),
              child: Center(
                child: Text(
                  defaultIcon,
                  style: TextStyle(fontSize: size * 0.5),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(size / 4), // Rounded corners instead of circular
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          },
        ),
      );
    } else {
      print('ServerIconWidget: No icon URL, showing emoji: $defaultIcon');
      // Show emoji icon
      iconWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size / 4), // Rounded corners instead of circular
        ),
        child: Center(
          child: Text(
            defaultIcon,
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      );
    }

    if (showBorder) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 4), // Rounded corners instead of circular
          border: Border.all(
            color: isActive ? backgroundColor : const Color(0xFFE9ECEF),
            width: isActive ? 2 : 1,
          ),
        ),
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}

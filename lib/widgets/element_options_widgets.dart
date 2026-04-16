import 'package:flutter/material.dart';

class ElementOptionsWidgets {
  Widget buildElementOption(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.black87),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(color: Colors.black87, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSelectableElementOption(
    String text,
    IconData icon,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      builder: (context, t, child) {
        final currentBg = Color.lerp(
          Colors.transparent,
          Colors.blueAccent.withValues(alpha: 0.15),
          t,
        )!;
        final currentContent = Color.lerp(
          Colors.black87,
          Colors.blueAccent,
          t,
        )!;

        final currentScale = 1.0 + (0.05 * t);

        return Transform.scale(
          scale: currentScale,
          child: Material(
            color: currentBg,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: currentContent),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        color: currentContent,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget buildElementOptionWithPopup(
    String text,
    dynamic popup,
    IconData icon,
    VoidCallback onPressed,
  ) {
    bool isSelected = false;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      builder: (context, t, child) {
        final currentBg = Color.lerp(
          Colors.transparent,
          Colors.blueAccent.withValues(alpha: 0.15),
          t,
        )!;
        final currentContent = Color.lerp(
          Colors.black87,
          Colors.blueAccent,
          t,
        )!;

        final currentScale = 1.0 + (0.05 * t);

        return Transform.scale(
          scale: currentScale,
          child: Material(
            color: currentBg,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: currentContent),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        color: currentContent,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    // return Column(
    //   children: [
    //     // Text(text, style: TextStyle(color: Colors.black)),
    //     popup,
    //   ],
    // );
  }

  Widget buildIconBtn(
    IconData icon,
    bool isEnabled,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, size: 22),
      color: Colors.black87,
      isSelected: isSelected,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black26;
          }
          return Colors.transparent;
        }),
      ),
      disabledColor: Colors.grey.withValues(alpha: 0.4),
      onPressed: isEnabled ? onPressed : null,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
    );
  }
}

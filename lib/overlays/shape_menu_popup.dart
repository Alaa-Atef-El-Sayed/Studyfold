import 'package:flutter/material.dart';
import 'package:studyfold/models/shape_config.dart';
import 'package:studyfold/models/shape_type.dart';

class ShapeMenuPopup extends StatefulWidget {
  final ShapeConfig currentConfig;
  final ValueChanged<ShapeConfig> onConfigChanged;
  final bool isSelected;
  final VoidCallback setSelected;
  final GlobalKey shapeToolKey;

  const ShapeMenuPopup({
    super.key,
    required this.currentConfig,
    required this.onConfigChanged,
    required this.isSelected,
    required this.setSelected,
    required this.shapeToolKey,
  });

  @override
  State<ShapeMenuPopup> createState() => _ShapeMenuPopupState();
}

class _ShapeMenuPopupState extends State<ShapeMenuPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  LocalHistoryEntry? _historyEntry;

  late ShapeConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.currentConfig;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    final curve = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(curve);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShapeMenuPopup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isOpen && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
  }

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _togglePopup() {
    if (_isOpen)
      _closePopup();
    else
      _showPopup();
  }

  void _closePopup() {
    _historyEntry?.remove();
    _historyEntry = null;
  }

  void _animateClose() async {
    await _animationController.reverse();
    if (mounted) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isOpen = false);
    }
  }

  void _showPopup() {
    final RenderBox buttonBox =
        widget.shapeToolKey.currentContext!.findRenderObject() as RenderBox;
    final Offset buttonPos = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;
    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets padding = MediaQuery.of(context).padding;

    const double minSpaceBelow = 250.0;

    final double spaceBelow =
        screenSize.height - (buttonPos.dy + buttonSize.height) - padding.bottom;
    final double spaceAbove = buttonPos.dy - padding.top;

    bool showAbove = false;

    if (spaceBelow < minSpaceBelow && spaceAbove > spaceBelow) {
      showAbove = true;
    }

    final bool alignRight = buttonPos.dx > screenSize.width / 2;

    final Alignment targetAnchor =
        (showAbove ? Alignment.topCenter : Alignment.bottomCenter) +
        (alignRight ? Alignment.centerRight : Alignment.centerLeft);

    final Alignment followerAnchor =
        (showAbove ? Alignment.bottomCenter : Alignment.topCenter) +
        (alignRight ? Alignment.centerRight : Alignment.centerLeft);

    _historyEntry = LocalHistoryEntry(onRemove: _animateClose);
    ModalRoute.of(context)?.addLocalHistoryEntry(_historyEntry!);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closePopup,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: targetAnchor,
              followerAnchor: followerAnchor,
              offset: Offset(0, showAbove ? -8 : 8),
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: followerAnchor,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    child: SizedBox(width: 260, child: _buildPopupContent()),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() => _isOpen = true);
  }

  Widget _buildPopupContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "SHAPE TOOL",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildShapeOption(
                Icons.crop_square_rounded,
                ShapeType.rectangle,
              ),
              _buildShapeOption(Icons.circle_outlined, ShapeType.circle),
              _buildShapeOption(
                Icons.change_history_rounded,
                ShapeType.triangle,
              ),
              // _buildShapeOption(Icons.star_outline_rounded, ShapeType.star),     // Star
              _buildShapeOption(
                Icons.horizontal_rule_rounded,
                ShapeType.line,
              ), // Line
            ],
          ),
        ),

        const Divider(height: 24),

        _buildSwitchOption(
          "Draw from Center",
          Icons.center_focus_strong_rounded,
          _config.drawFromCenter,
          (val) => _updateConfig(_config.copyWith(drawFromCenter: val)),
        ),

        _buildSwitchOption(
          "Lock Aspect Ratio (1:1)",
          Icons.aspect_ratio_rounded,
          _config.lockAspectRatio,
          (val) => _updateConfig(_config.copyWith(lockAspectRatio: val)),
        ),

        const Divider(height: 24),

        // 4. Style Options (Future Proofing)
        _buildSwitchOption(
          "Fill Shape",
          Icons.format_color_fill_rounded,
          _config.fill,
          (val) => _updateConfig(_config.copyWith(fill: val)),
        ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Border Radius: ${_config.borderRadius.toInt()}",
                  style: const TextStyle(fontSize: 12),
                ),
                SizedBox(
                  height: 30,
                  child: Slider(
                    value: _config.borderRadius,
                    min: 0,
                    max: 50,
                    onChanged: (val) =>
                        _updateConfig(_config.copyWith(borderRadius: val)),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildShapeOption(IconData icon, ShapeType type) {
    final isSelected = _config.shapeType == type;
    return GestureDetector(
      onTap: () => _updateConfig(_config.copyWith(shapeType: type)),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[700],
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSwitchOption(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            SizedBox(
              height: 24,
              width: 40,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateConfig(ShapeConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    // Notify parent immediately so the tool works without closing the popup
    widget.onConfigChanged(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        icon: Icon(
          _getIconForShape(_config.shapeType),
          color: _isOpen ? Colors.blue : Colors.black87,
          size: 22,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        isSelected: widget.isSelected,
        onPressed: (widget.isSelected) ? _togglePopup : widget.setSelected,
        tooltip: "Shape Tool",
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
      ),
    );
  }

  IconData _getIconForShape(ShapeType type) {
    switch (type) {
      case ShapeType.rectangle:
        return Icons.crop_square_rounded;
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.triangle:
        return Icons.change_history_rounded;
      // case ShapeType.star: return Icons.star_outline_rounded;
      case ShapeType.line:
        return Icons.horizontal_rule_rounded;
    }
  }
}

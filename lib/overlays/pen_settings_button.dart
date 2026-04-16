import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class PenSettingsButton extends StatefulWidget {
  final double currentSize;
  final Color currentColor;
  final Function(double) onSizeChanged;
  final Function(Color) onColorChanged;
  final bool isSelected;
  final VoidCallback setSelected;
  final GlobalKey penButtonKey;

  const PenSettingsButton({
    super.key,
    required this.currentSize,
    required this.currentColor,
    required this.onSizeChanged,
    required this.onColorChanged,
    required this.isSelected,
    required this.setSelected,
    required this.penButtonKey,
  });

  @override
  State<PenSettingsButton> createState() => _PenSettingsButtonState();
}

class _PenSettingsButtonState extends State<PenSettingsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  LocalHistoryEntry? _historyEntry;

  @override
  void initState() {
    super.initState();
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

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _togglePopup() {
    if (_isOpen) {
      _closePopup();
    } else {
      _showPopup();
    }
  }

  void _closePopup() async {
    await _animationController.reverse();
    _historyEntry?.remove();
    _historyEntry = null;

    if (mounted) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isOpen = false);
    }
  }

  void _animateClose() async {
    await _animationController.reverse();

    if (mounted) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isOpen = false);
    }
  }

  @override
  void didUpdateWidget(covariant PenSettingsButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isOpen && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
  }

  void _showPopup() {
    final RenderBox buttonBox =
        widget.penButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset buttonPos = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;
    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets padding = MediaQuery.of(context).padding;

    const double minSpaceBelow = 160.0;

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
                    child: SizedBox(width: 250, height: 150, child: _buildPopupContent()),
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

  void _showPopupE() {
    _historyEntry = LocalHistoryEntry(
      onRemove: () {
        _animateClose();
      },
    );

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
              offset: const Offset(-125, -160),

              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 250,
                      height: 150,
                      child: _buildPopupContent(),
                    ),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Pen Settings",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),

        Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.circle, size: 8),
            ),
            Expanded(
              child: Slider(
                value: widget.currentSize,
                min: 1.0,
                max: 100.0,
                onChanged: widget.onSizeChanged,
              ),
            ),
          ],
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _colorDot(Colors.black),
            _colorDot(Colors.red),
            _colorDot(Colors.blue),
            _colorDot(Colors.green),
            GestureDetector(
              onTap: () {
                _closePopup();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Pick a Color"),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: widget.currentColor,
                        onColorChanged: widget.onColorChanged,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Done"),
                      ),
                    ],
                  ),
                );
              },
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey,
                child: Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _colorDot(Color color) {
    bool isSelected = widget.currentColor.value == color.value;
    return GestureDetector(
      onTap: () => widget.onColorChanged(color),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 2)
              : null,
        ),
        child: CircleAvatar(backgroundColor: color, radius: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        icon: Icon(
          Icons.edit,
          color: _isOpen ? Colors.blue : Colors.black87,
          size: 22,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        tooltip: "Pen Settings",
        isSelected: widget.isSelected,
        onPressed: (widget.isSelected) ? _togglePopup : widget.setSelected,
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
}

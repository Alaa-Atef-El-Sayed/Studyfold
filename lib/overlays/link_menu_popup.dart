import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class LinkMenuPopup extends StatefulWidget {
  final Function() addImage;
  final Function() addDocument;
  final GlobalKey linkMenuKey;

  const LinkMenuPopup({
    super.key,
    required this.addImage,
    required this.addDocument,
    required this.linkMenuKey,
  });

  @override
  State<LinkMenuPopup> createState() => _LinkMenuPopupState();
}

class _LinkMenuPopupState extends State<LinkMenuPopup>
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
  void didUpdateWidget(covariant LinkMenuPopup oldWidget) {
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
        widget.linkMenuKey.currentContext!.findRenderObject() as RenderBox;
    final Offset buttonPos = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;
    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets padding = MediaQuery.of(context).padding;

    const double minSpaceBelow = 150.0;

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
              targetAnchor: targetAnchor,
              followerAnchor: followerAnchor,
              offset: Offset(0, showAbove ? -8 : 8),

              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: followerAnchor,
                // alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildPopupContent(),
                      ),
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

  List<Widget> _buildPopupContent() {
    return [
      _buildMenuItem(icon: Icons.image, label: "Image", onTap: widget.addImage),
      const Divider(height: 1, thickness: 0.5),
      _buildMenuItem(
        icon: Icons.description,
        label: "Document",
        onTap: widget.addDocument,
      ),
      const Divider(height: 1, thickness: 0.5),
      _buildMenuItem(
        icon: Icons.audiotrack_rounded,
        label: "Audio",
        onTap: () {},
      ),
    ];
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        _closePopup();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        icon: Icon(
          Icons.add_link,
          color: _isOpen ? Colors.blue : Colors.black87,
          size: 22,
        ),
        onPressed: _togglePopup,
      ),
    );
  }
}

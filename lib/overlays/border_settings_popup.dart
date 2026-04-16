import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:studyfold/Icons/my_custom_icons.dart';
import 'package:studyfold/models/hive_shape.dart';
import 'package:studyfold/models/shape_config.dart';
import 'package:studyfold/widgets/color_circle.dart';
import 'package:studyfold/widgets/element_options_widgets.dart';

class BorderSettingsPopup extends StatefulWidget {
  final ValueChanged<ShapeConfig> onConfigChanged;
  final ValueChanged<Size> onDimensionsChanged;
  final ValueChanged<Color> onColorChanged;
  final HiveShape shape;

  const BorderSettingsPopup({
    super.key,
    required this.onConfigChanged,
    required this.onDimensionsChanged,
    required this.onColorChanged,
    required this.shape,
  });

  @override
  State<BorderSettingsPopup> createState() => _BorderSettingsPopupState();
}

class _BorderSettingsPopupState extends State<BorderSettingsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  LocalHistoryEntry? _historyEntry;

  late ShapeConfig _config;
  late Size _dimensions;
  late Offset _position;
  late Color _selectedColor;

  final ElementOptionsWidgets elementOptionsWidgets = ElementOptionsWidgets();

  @override
  void initState() {
    super.initState();
    _config = widget.shape.config;
    _position = Offset(
      widget.shape.shapeStartPoint.dx,
      widget.shape.shapeStartPoint.dy,
    );
    _dimensions = Size(
      (widget.shape.shapeStartPoint.dx - widget.shape.shapeEndPoint.dx).abs(),
      (widget.shape.shapeStartPoint.dy - widget.shape.shapeEndPoint.dy).abs(),
    );
    _selectedColor = Color(widget.shape.colorValue);
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
  void didUpdateWidget(covariant BorderSettingsPopup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shape != oldWidget.shape) {
      _config = widget.shape.config;
      _position = Offset(
        widget.shape.shapeStartPoint.dx,
        widget.shape.shapeStartPoint.dy,
      );
      _dimensions = Size(
        (widget.shape.shapeStartPoint.dx - widget.shape.shapeEndPoint.dx).abs(),
        (widget.shape.shapeStartPoint.dy - widget.shape.shapeEndPoint.dy).abs(),
      );
      _selectedColor = Color(widget.shape.colorValue);

      if (_isOpen) {
        _closePopup();
      }
    }

    if (_isOpen && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
  }

  void _showPopup() {
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
              offset: const Offset(0, 0),

              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.1),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.bottomCenter,
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
      _buildPositionInputs(_position.dx, _position.dy, (newWidth, newHeight) {
        setState(() {
          _dimensions = Size(newWidth, newHeight);
        });

        widget.onDimensionsChanged(_dimensions);
      }),
      _buildDimensionInputs(_dimensions.width, _dimensions.height, (
        newWidth,
        newHeight,
      ) {
        setState(() {
          _dimensions = Size(newWidth, newHeight);
        });

        widget.onDimensionsChanged(_dimensions);
      }),
      _buildSlider(
        "Border Width",
        _config.borderWidth,
        10.0,
        (value) => _updateConfig(_config.copyWith(borderWidth: value)),
      ),
      _buildSlider(
        "Border Radius",
        _config.borderRadius,
        40.0,
        (value) => _updateConfig(_config.copyWith(borderRadius: value)),
      ),
      _buildSwitchOption(
        "Fill Shape",
        Icons.format_color_fill_rounded,
        _config.fill,
        (value) => _updateConfig(_config.copyWith(fill: value)),
      ),
      _buildColorChangeOption(),
    ];
  }

  Widget _buildSlider(
    String sliderText,
    double sliderValue,
    double sliderMaxValue,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(sliderText, style: TextStyle(fontSize: 18)),
          Slider(
            value: sliderValue,
            min: 0.0,
            max: sliderMaxValue,
            onChanged: onChanged,
          ),
        ],
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
        padding: const EdgeInsets.only(right: 24, top: 8, bottom: 8, left: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
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

  Widget _buildPositionInputs(
    double currentX,
    double currentY,
    Function(double x, double y) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactNumberField(
              label: "X",
              value: currentX.round().toString(),
              onChanged: (val) {
                double? newX = double.tryParse(val);
                if (newX != null) onChanged(newX, currentX);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCompactNumberField(
              label: "Y",
              value: currentY.round().toString(),
              onChanged: (val) {
                double? newY = double.tryParse(val);
                if (newY != null) onChanged(currentY, newY);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionInputs(
    double currentWidth,
    double currentHeight,
    Function(double width, double height) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactNumberField(
              label: "W",
              value: currentWidth.round().toString(),
              onChanged: (val) {
                double? newW = double.tryParse(val);
                if (newW != null) onChanged(newW, currentHeight);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCompactNumberField(
              label: "H",
              value: currentHeight.round().toString(),
              onChanged: (val) {
                double? newH = double.tryParse(val);
                if (newH != null) onChanged(currentWidth, newH);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNumberField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 32,
            child: TextFormField(
              initialValue: value,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      BorderSide.none, // Clean look without harsh borders
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorChangeOption() {
    return InkWell(
      onTap: () {
        ColorCircle.showColorPickerDialog(
          context: context,
          onColorChanged: widget.onColorChanged,
          selectedColor: _selectedColor,
          onTapBeforeDialog: _closePopup,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 16, bottom: 8, top: 8),
        child: Row(
          children: [
            Text("Fill Color"),

            Spacer(),

            ColorCircle(selectedColor: _selectedColor),
          ],
        ),
      ),
    );
  }

  void _updateConfig(ShapeConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,

      child: elementOptionsWidgets.buildSelectableElementOption(
        "Options",
        MyCustomIcons.paintcan,
        _isOpen,
        _togglePopup,
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return elementOptionsWidgets.buildSelectableElementOption(
  //     "Shape Options",
  //     MyCustomIcons.paintcan,
  //     _isOpen,
  //     _togglePopup,
  //   );
  //   // return CompositedTransformTarget(
  //   //   link: _layerLink,
  //   //   child: IconButton(
  //   //     icon: Icon(
  //   //       MyCustomIcons.paintcan,
  //   //       color: _isOpen ? Colors.blue : Colors.black87,
  //   //       size: 22,
  //   //     ),
  //   //     onPressed: _togglePopup,
  //   //   ),
  //   // );
  // }
}

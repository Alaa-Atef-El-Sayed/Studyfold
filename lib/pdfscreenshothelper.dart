import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class ScreenshotHelper {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<Uint8List?> captureWidget(Widget widget, {double pixelRatio = 2.0}) async {
    try {
      return await _screenshotController.captureFromWidget(
        SizedBox(
          width: 500,
          height: 2000,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(500, 1000),
              devicePixelRatio: pixelRatio,
            ),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: Colors.white,
                body: widget
              ),
            ),
          ),
        ),
        pixelRatio: pixelRatio,
        delay: Duration(milliseconds: 300),
      );
    } catch (e) {
      debugPrint('Screenshot error: $e');
      return null;
    }
  }
}
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

import 'object.dart';
import 'stack.dart';

String _formatPixels(double value) {
  assert(value > 0.0);
  String pixels;
  if (value >= 10.0) {
    pixels = value.toStringAsFixed(0);
  } else if (value > 1.0) {
    pixels = value.toStringAsFixed(1);
  } else {
    pixels = value.toStringAsPrecision(3);
  }
  return pixels;
}

// Describes which side the region data overflows on.
enum _OverflowSide {
  left,
  top,
  bottom,
  right,
}

// Data used by the DebugOverflowIndicator to manage the regions and labels for
// the indicators.
class _OverflowRegionData {
  const _OverflowRegionData({
    this.rect,
    this.label = '',
    this.labelOffset = Offset.zero,
    this.rotation = 0.0,
    this.side,
  });

  final Rect rect;
  final String label;
  final Offset labelOffset;
  final double rotation;
  final _OverflowSide side;
}

/// Signature for callbacks that report overflow errors to the console.
///
/// See also:
///   * [OverflowErrorDetails], which holds information about an overflow error.
///   * [DebugOverflowIndicatorMixin], which uses these callbacks.
typedef OverflowErrorReporter = void Function(OverflowErrorDetails data);

/// Information gathered when an overflow has been detected.
///
/// See also:
///   * [DebugOverflowIndicatorMixin], which uses this data to report overflow errors.
class OverflowErrorDetails {
  /// Creates overflow details with the specified geometry and render object.
  ///
  /// The [overflow] field should not be null.
  OverflowErrorDetails({
    @required this.overflow,
    this.hints,
  }) : assert(overflow != null);

  /// The overflow geometry, relative to the edges of [renderObject].
  final RelativeRect overflow;

  /// Additional information that may be included in [FlutterErrorDetails.informationCollector]
  /// by the [OverflowErrorReporter], or null if default hints should be used.
  final List<DiagnosticsNode> hints;

  /// Creates a human readable description of how far [overflow] extends in each
  /// direction, for use in error messages.
  ///
  /// For example, if [overflow] is `RelativeRect.fromLTRB(0.0, -5,0, 20.0, 30.0)`,
  /// this method would return "30 pixels on the bottom and 20 pixels on the right".
  String describeOverflow() {
    final List<String> overflows = <String>[
      if (overflow.left > 0.0) '${_formatPixels(overflow.left)} pixels on the left',
      if (overflow.top > 0.0) '${_formatPixels(overflow.top)} pixels on the top',
      if (overflow.bottom > 0.0) '${_formatPixels(overflow.bottom)} pixels on the bottom',
      if (overflow.right > 0.0) '${_formatPixels(overflow.right)} pixels on the right',
    ];

    String description = '';
    assert(overflows.isNotEmpty, 'OverflowErrorDetails was given an overflow RelativeRect that does not overflow');
    switch (overflows.length) {
      case 1:
        description = overflows.first;
        break;
      case 2:
        description = '${overflows.first} and ${overflows.last}';
        break;
      default:
        overflows[overflows.length - 1] = 'and ${overflows[overflows.length - 1]}';
        description = overflows.join(', ');
    }
    return description;
  }
}

/// An mixin indicator that is drawn when a [RenderObject] overflows its
/// container.
///
/// This is used by some RenderObjects that are containers to show where, and by
/// how much, their children overflow their containers. These indicators are
/// typically only shown in a debug build (where the call to
/// [paintOverflowIndicator] is surrounded by an assert).
///
/// Override [debugReportOverflow] to change how overflow errors are handled,
/// this is useful if you want to add extra context to the error message, such
/// as what child widget caused it.
///
/// The default reporting behavior is to print a debug message to the console
/// with information relevant to debugging the render object. The reporter will
/// only be called on the first occurrence of an overflow, or once after
/// [reassemble] is called.
///
/// {@tool snippet}
///
/// ```dart
/// class MyRenderObject extends RenderAligningShiftedBox with DebugOverflowIndicatorMixin {
///   MyRenderObject({
///     AlignmentGeometry alignment,
///     TextDirection textDirection,
///     RenderBox child,
///   }) : super.mixin(alignment, textDirection, child);
///
///   Rect _containerRect;
///   Rect _childRect;
///
///   @override
///   void performLayout() {
///     // ...
///     final BoxParentData childParentData = child.parentData;
///     _containerRect = Offset.zero & size;
///     _childRect = childParentData.offset & child.size;
///   }
///
///   @override
///   void paint(PaintingContext context, Offset offset) {
///     // Do normal painting here...
///     // ...
///
///     assert(() {
///       paintOverflowIndicator(context, offset, _containerRect, _childRect);
///       return true;
///     }());
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RenderUnconstrainedBox] and [RenderFlex] for examples of classes that use this indicator mixin.
mixin DebugOverflowIndicatorMixin on RenderObject {
  static const Color _black = Color(0xBF000000);
  static const Color _yellow = Color(0xBFFFFF00);
  // The fraction of the container that the indicator covers.
  static const double _indicatorFraction = 0.1;
  static const double _indicatorFontSizePixels = 7.5;
  static const double _indicatorLabelPaddingPixels = 1.0;
  static const TextStyle _indicatorTextStyle = TextStyle(
    color: Color(0xFF900000),
    fontSize: _indicatorFontSizePixels,
    fontWeight: FontWeight.w800,
  );
  static final Paint _indicatorPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0.0, 0.0),
      const Offset(10.0, 10.0),
      const <Color>[_black, _yellow, _yellow, _black],
      const <double>[0.25, 0.25, 0.75, 0.75],
      TileMode.repeated,
    );
  static final Paint _labelBackgroundPaint = Paint()..color = const Color(0xFFFFFFFF);

  final List<TextPainter> _indicatorLabel = List<TextPainter>.filled(
    _OverflowSide.values.length,
    TextPainter(textDirection: TextDirection.ltr), // This label is in English.
  );

  /// Reports an overflow error to the console.
  ///
  /// Override this method to change how overflow errors are handled by the
  /// [DebugOverflowIndicatorMixin] mixin.
  ///
  /// The default implementation is sufficient for diagnosing issues in the
  /// render layer, however, it may lack useful context such as the exact widget
  /// that caused the overflow.
  void debugReportOverflow(OverflowErrorDetails details) {
    final List<DiagnosticsNode> hints = details.hints ?? <DiagnosticsNode>[
      ErrorDescription(
        'The edge of the $runtimeType that is '
        'overflowing has been marked in the rendering with a yellow and black '
        'striped pattern. This is usually caused by the contents being too big '
        'for the $runtimeType.'
      ),
      ErrorHint(
        'This is considered an error condition because it indicates that there '
        'is content that cannot be seen. If the content is legitimately bigger '
        'than the available space, consider clipping it with a ClipRect widget '
        'before putting it in the $runtimeType, or using a scrollable '
        'container, like a ListView.'
      ),
    ];

    // TODO(jacobr): add the overflows in pixels as structured data so they can
    // be visualized in debugging tools.
    FlutterError.reportError(
      FlutterErrorDetailsForRendering(
        exception: FlutterError('A $runtimeType overflowed by ${details.describeOverflow()}.'),
        library: 'rendering library',
        context: ErrorDescription('during layout'),
        renderObject: this,
        informationCollector: () sync* {
          if (debugCreator != null)
            yield DiagnosticsDebugCreator(debugCreator);
          yield* hints;
          yield describeForError('The specific $runtimeType in question is');
          // TODO(jacobr): this line is ascii art that it would be nice to
          // handle a little more generically in GUI debugging clients in the
          // future.
          yield DiagnosticsNode.message('◢◤' * (FlutterError.wrapWidth ~/ 2), allowWrap: false);
        },
      ),
    );
  }

  // Set to true to trigger a debug message in the console upon
  // the next paint call. Will be reset after each paint.
  bool _overflowReportNeeded = true;

  List<_OverflowRegionData> _calculateOverflowRegions(RelativeRect overflow, Rect containerRect) {
    final List<_OverflowRegionData> regions = <_OverflowRegionData>[];
    if (overflow.left > 0.0) {
      final Rect markerRect = Rect.fromLTWH(
        0.0,
        0.0,
        containerRect.width * _indicatorFraction,
        containerRect.height,
      );
      regions.add(_OverflowRegionData(
        rect: markerRect,
        label: 'LEFT OVERFLOWED BY ${_formatPixels(overflow.left)} PIXELS',
        labelOffset: markerRect.centerLeft +
            const Offset(_indicatorFontSizePixels + _indicatorLabelPaddingPixels, 0.0),
        rotation: math.pi / 2.0,
        side: _OverflowSide.left,
      ));
    }
    if (overflow.right > 0.0) {
      final Rect markerRect = Rect.fromLTWH(
        containerRect.width * (1.0 - _indicatorFraction),
        0.0,
        containerRect.width * _indicatorFraction,
        containerRect.height,
      );
      regions.add(_OverflowRegionData(
        rect: markerRect,
        label: 'RIGHT OVERFLOWED BY ${_formatPixels(overflow.right)} PIXELS',
        labelOffset: markerRect.centerRight -
            const Offset(_indicatorFontSizePixels + _indicatorLabelPaddingPixels, 0.0),
        rotation: -math.pi / 2.0,
        side: _OverflowSide.right,
      ));
    }
    if (overflow.top > 0.0) {
      final Rect markerRect = Rect.fromLTWH(
        0.0,
        0.0,
        containerRect.width,
        containerRect.height * _indicatorFraction,
      );
      regions.add(_OverflowRegionData(
        rect: markerRect,
        label: 'TOP OVERFLOWED BY ${_formatPixels(overflow.top)} PIXELS',
        labelOffset: markerRect.topCenter + const Offset(0.0, _indicatorLabelPaddingPixels),
        rotation: 0.0,
        side: _OverflowSide.top,
      ));
    }
    if (overflow.bottom > 0.0) {
      final Rect markerRect = Rect.fromLTWH(
        0.0,
        containerRect.height * (1.0 - _indicatorFraction),
        containerRect.width,
        containerRect.height * _indicatorFraction,
      );
      regions.add(_OverflowRegionData(
        rect: markerRect,
        label: 'BOTTOM OVERFLOWED BY ${_formatPixels(overflow.bottom)} PIXELS',
        labelOffset: markerRect.bottomCenter -
            const Offset(0.0, _indicatorFontSizePixels + _indicatorLabelPaddingPixels),
        rotation: 0.0,
        side: _OverflowSide.bottom,
      ));
    }
    return regions;
  }

  /// To be called when the overflow indicators should be painted.
  ///
  /// Typically only called if there is an overflow, and only from within a
  /// debug build.
  ///
  /// See example code in [DebugOverflowIndicatorMixin] documentation.
  void paintOverflowIndicator(
    PaintingContext context,
    Offset offset,
    Rect containerRect,
    Rect childRect, {
    List<DiagnosticsNode> overflowHints,
  }) {
    final RelativeRect overflow = RelativeRect.fromRect(containerRect, childRect);

    if (overflow.left <= 0.0 &&
        overflow.right <= 0.0 &&
        overflow.top <= 0.0 &&
        overflow.bottom <= 0.0) {
      return;
    }

    final List<_OverflowRegionData> overflowRegions = _calculateOverflowRegions(overflow, containerRect);
    for (final _OverflowRegionData region in overflowRegions) {
      context.canvas.drawRect(region.rect.shift(offset), _indicatorPaint);
      final TextSpan textSpan = _indicatorLabel[region.side.index].text as TextSpan;
      if (textSpan?.text != region.label) {
        _indicatorLabel[region.side.index].text = TextSpan(
          text: region.label,
          style: _indicatorTextStyle,
        );
        _indicatorLabel[region.side.index].layout();
      }

      final Offset labelOffset = region.labelOffset + offset;
      final Offset centerOffset = Offset(-_indicatorLabel[region.side.index].width / 2.0, 0.0);
      final Rect textBackgroundRect = centerOffset & _indicatorLabel[region.side.index].size;
      context.canvas.save();
      context.canvas.translate(labelOffset.dx, labelOffset.dy);
      context.canvas.rotate(region.rotation);
      context.canvas.drawRect(textBackgroundRect, _labelBackgroundPaint);
      _indicatorLabel[region.side.index].paint(context.canvas, centerOffset);
      context.canvas.restore();
    }

    if (_overflowReportNeeded) {
      _overflowReportNeeded = false;
      debugReportOverflow(OverflowErrorDetails(
        overflow: overflow,
        hints: overflowHints,
      ));
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Users expect error messages to be shown again after hot reload.
    assert(() {
      _overflowReportNeeded = true;
      return true;
    }());
  }
}

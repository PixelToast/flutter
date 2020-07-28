// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'button_bar_theme.dart';
import 'button_theme.dart';
import 'dialog.dart';
import 'flat_button.dart';
import 'raised_button.dart';

/// An end-aligned row of buttons, laying out into a column if there is not
/// enough horizontal space.
///
/// Places the buttons horizontally according to the [buttonPadding]. The
/// children are laid out in a [Row] with [MainAxisAlignment.end]. When the
/// [Directionality] is [TextDirection.ltr], the button bar's children are
/// right justified and the last child becomes the rightmost child. When the
/// [Directionality] [TextDirection.rtl] the children are left justified and
/// the last child becomes the leftmost child.
///
/// If the button bar's width exceeds the maximum width constraint on the
/// widget, it aligns its buttons in a column. The key difference here
/// is that the [MainAxisAlignment] will then be treated as a
/// cross-axis/horizontal alignment. For example, if the buttons overflow and
/// [ButtonBar.alignment] was set to [MainAxisAlignment.start], the buttons would
/// align to the horizontal start of the button bar.
///
/// The [ButtonBar] can be configured with a [ButtonBarTheme]. For any null
/// property on the ButtonBar, the surrounding ButtonBarTheme's property
/// will be used instead. If the ButtonBarTheme's property is null
/// as well, the property will default to a value described in the field
/// documentation below.
///
/// The [children] are wrapped in a [ButtonTheme] that is a copy of the
/// surrounding ButtonTheme with the button properties overridden by the
/// properties of the ButtonBar as described above. These properties include
/// [buttonTextTheme], [buttonMinWidth], [buttonHeight], [buttonPadding],
/// and [buttonAlignedDropdown].
///
/// Used by [Dialog] to arrange the actions at the bottom of the dialog.
///
/// See also:
///
///  * [RaisedButton], a kind of button.
///  * [FlatButton], another kind of button.
///  * [Card], at the bottom of which it is common to place a [ButtonBar].
///  * [Dialog], which uses a [ButtonBar] for its actions.
///  * [ButtonBarTheme], which configures the [ButtonBar].
class ButtonBar extends StatelessWidget {
  /// Creates a button bar.
  ///
  /// Both [buttonMinWidth] and [buttonHeight] must be non-negative if they
  /// are not null.
  const ButtonBar({
    Key key,
    this.alignment,
    this.mainAxisSize,
    this.buttonTextTheme,
    this.buttonMinWidth,
    this.buttonHeight,
    this.buttonPadding,
    this.buttonAlignedDropdown,
    this.layoutBehavior,
    this.overflowDirection,
    this.overflowButtonSpacing,
    this.textDirection,
    this.children = const <Widget>[],
  }) : assert(buttonMinWidth == null || buttonMinWidth >= 0.0),
       assert(buttonHeight == null || buttonHeight >= 0.0),
       assert(overflowButtonSpacing == null || overflowButtonSpacing >= 0.0),
       super(key: key);

  /// How the children should be placed along the horizontal axis.
  ///
  /// If null then it will use [ButtonBarTheme.alignment]. If that is null,
  /// it will default to [MainAxisAlignment.end].
  final MainAxisAlignment alignment;

  /// How much horizontal space is available. See [Row.mainAxisSize].
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.mainAxisSize].
  /// If that is null, it will default to [MainAxisSize.max].
  final MainAxisSize mainAxisSize;

  /// Overrides the surrounding [ButtonTheme.textTheme] to define a button's
  /// base colors, size, internal padding and shape.
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonTextTheme].
  /// If that is null, it will default to [ButtonTextTheme.primary].
  final ButtonTextTheme buttonTextTheme;

  /// Overrides the surrounding [ButtonThemeData.minWidth] to define a button's
  /// minimum width.
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonMinWidth].
  /// If that is null, it will default to 64.0 logical pixels.
  final double buttonMinWidth;

  /// Overrides the surrounding [ButtonThemeData.height] to define a button's
  /// minimum height.
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonHeight].
  /// If that is null, it will default to 36.0 logical pixels.
  final double buttonHeight;

  /// Overrides the surrounding [ButtonThemeData.padding] to define the padding
  /// for a button's child (typically the button's label).
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonPadding].
  /// If that is null, it will default to 8.0 logical pixels on the left
  /// and right.
  final EdgeInsetsGeometry buttonPadding;

  /// Overrides the surrounding [ButtonThemeData.alignedDropdown] to define whether
  /// a [DropdownButton] menu's width will match the button's width.
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonAlignedDropdown].
  /// If that is null, it will default to false.
  final bool buttonAlignedDropdown;

  /// Defines whether a [ButtonBar] should size itself with a minimum size
  /// constraint or with padding.
  ///
  /// Overrides the surrounding [ButtonThemeData.layoutBehavior].
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.layoutBehavior].
  /// If that is null, it will default [ButtonBarLayoutBehavior.padded].
  final ButtonBarLayoutBehavior layoutBehavior;

  /// Defines the vertical direction of a [ButtonBar]'s children if it
  /// overflows.
  ///
  /// If [children] do not fit into a single row, then they
  /// are arranged in a column. The first action is at the top of the
  /// column if this property is set to [VerticalDirection.down], since it
  /// "starts" at the top and "ends" at the bottom. On the other hand,
  /// the first action will be at the bottom of the column if this
  /// property is set to [VerticalDirection.up], since it "starts" at the
  /// bottom and "ends" at the top.
  ///
  /// If null then it will use the surrounding
  /// [ButtonBarTheme.overflowDirection]. If that is null, it will
  /// default to [VerticalDirection.down].
  final VerticalDirection overflowDirection;

  /// The spacing between buttons when the button bar overflows.
  ///
  /// If the [children] do not fit into a single row, they are
  /// arranged into a column. This parameter provides additional
  /// vertical space in between buttons when it does overflow.
  ///
  /// Note that the button spacing may appear to be more than
  /// the value provided. This is because most buttons adhere to the
  /// [MaterialTapTargetSize] of 48px. So, even though a button
  /// might visually be 36px in height, it might still take up to
  /// 48px vertically.
  ///
  /// If null then no spacing will be added in between buttons in
  /// an overflow state.
  final double overflowButtonSpacing;

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// Defaults to the ambient [Directionality].
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// the children are positioned (left-to-right or right-to-left), and the
  /// meaning of the [mainAxisAlignment] property's [MainAxisAlignment.start] and
  /// [MainAxisAlignment.end] values.
  ///
  /// See also:
  ///   * [Row], which has similar text direction behavior.
  final TextDirection textDirection;

  /// The buttons to arrange horizontally.
  ///
  /// Typically [RaisedButton] or [FlatButton] widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData parentButtonTheme = ButtonTheme.of(context);
    final ButtonBarThemeData barTheme = ButtonBarTheme.of(context);

    final ButtonThemeData buttonTheme = parentButtonTheme.copyWith(
      textTheme: buttonTextTheme ?? barTheme.buttonTextTheme ?? ButtonTextTheme.primary,
      minWidth: buttonMinWidth ?? barTheme.buttonMinWidth ?? 64.0,
      height: buttonHeight ?? barTheme.buttonHeight ?? 36.0,
      padding: buttonPadding ?? barTheme.buttonPadding ?? const EdgeInsets.symmetric(horizontal: 8.0),
      alignedDropdown: buttonAlignedDropdown ?? barTheme.buttonAlignedDropdown ?? false,
      layoutBehavior: layoutBehavior ?? barTheme.layoutBehavior ?? ButtonBarLayoutBehavior.padded,
    );

    // We divide by 4.0 because we want half of the average of the left and right padding.
    final double paddingUnit = buttonTheme.padding.horizontal / 4.0;
    final Widget child = ButtonTheme.fromButtonThemeData(
      data: buttonTheme,
      child: _ButtonBarRow(
        children: children.map<Widget>((Widget child) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingUnit),
            child: child,
          );
        }).toList(),
        textDirection: textDirection ?? barTheme.textDirection ?? Directionality.of(context),
        mainAxisAlignment: alignment ?? barTheme.alignment ?? MainAxisAlignment.end,
        mainAxisSize: mainAxisSize ?? barTheme.mainAxisSize ?? MainAxisSize.max,
        overflowDirection: overflowDirection ?? barTheme.overflowDirection ?? VerticalDirection.down,
        overflowButtonSpacing: overflowButtonSpacing,
      ),
    );
    switch (buttonTheme.layoutBehavior) {
      case ButtonBarLayoutBehavior.padded:
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: 2.0 * paddingUnit,
            horizontal: paddingUnit,
          ),
          child: child,
        );
      case ButtonBarLayoutBehavior.constrained:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: paddingUnit),
          constraints: const BoxConstraints(minHeight: 52.0),
          alignment: Alignment.center,
          child: child,
        );
    }
    assert(false);
    return null;
  }
}

/// Attempts to display buttons in a row, but displays them in a column if
/// there is not enough horizontal space.
///
/// It first attempts to lay out its buttons as though there were no
/// maximum width constraints on the widget. If the button bar's width is
/// less than the maximum width constraints of the widget, it then lays
/// out the widget as though it were placed in a [Row].
///
/// However, if the button bar's width exceeds the maximum width constraint on
/// the widget, it then aligns its buttons in a column. The key difference here
/// is that the [MainAxisAlignment] will then be treated as a
/// cross-axis/horizontal alignment. For example, if the buttons overflow and
/// [ButtonBar.alignment] was set to [MainAxisAlignment.start], the column of
/// buttons would align to the horizontal start of the button bar.
class _ButtonBarRow extends MultiChildRenderObjectWidget {
  /// Creates a button bar that attempts to display in a row, but displays in
  /// a column if there is insufficient horizontal space.
  _ButtonBarRow({
    List<Widget> children,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.end,
    this.overflowDirection = VerticalDirection.down,
    this.overflowButtonSpacing,
    @required this.textDirection,
  }) : super(children: children);

  final TextDirection textDirection;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final VerticalDirection overflowDirection;
  final double overflowButtonSpacing;

  @override
  _RenderButtonBarRow createRenderObject(BuildContext context) {
    return _RenderButtonBarRow(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      overflowDirection: overflowDirection,
      overflowButtonSpacing: overflowButtonSpacing,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderButtonBarRow renderObject) {
    renderObject
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..overflowDirection = overflowDirection
      ..overflowButtonSpacing = overflowButtonSpacing
      ..textDirection = textDirection;
  }
}

class _ButtonBarParentData extends MultiChildLayoutParentData {
  double intrinsicWidth;
}

/// Attempts to display buttons in a row, but displays them in a column if
/// there is not enough horizontal space.
///
/// It first attempts to lay out its buttons as though there were no
/// maximum width constraints on the widget. If the button bar's width is
/// less than the maximum width constraints of the widget, it then lays
/// out the widget as though it were placed in a [Row].
///
/// However, if the button bar's width exceeds the maximum width constraint on
/// the widget, it then aligns its buttons in a column. The key difference here
/// is that the [MainAxisAlignment] will then be treated as a
/// cross-axis/horizontal alignment. For example, if the buttons overflow and
/// [ButtonBar.alignment] was set to [MainAxisAlignment.start], the buttons would
/// align to the horizontal start of the button bar.
class _RenderButtonBarRow extends RenderBox with
    ContainerRenderObjectMixin<RenderBox, _ButtonBarParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, _ButtonBarParentData>,
    DebugOverflowIndicatorMixin {
  /// Creates a button bar that attempts to display in a row, but displays in
  /// a column if there is insufficient horizontal space.
  _RenderButtonBarRow({
    List<RenderBox> children,
    @required TextDirection textDirection,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.end,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    VerticalDirection overflowDirection = VerticalDirection.down,
    double overflowButtonSpacing,
    Clip clipBehavior = Clip.hardEdge,
  }) : assert(textDirection != null),
       assert(mainAxisAlignment != null),
       assert(mainAxisSize != null),
       assert(overflowDirection != null),
       assert(overflowButtonSpacing == null || overflowButtonSpacing >= 0),
       assert(clipBehavior != null),
       _textDirection = textDirection,
       _mainAxisAlignment = mainAxisAlignment,
       _mainAxisSize = mainAxisSize,
       _overflowDirection = overflowDirection,
       _overflowButtonSpacing = overflowButtonSpacing {
    addAll(children);
  }

  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  MainAxisAlignment _mainAxisAlignment;
  set mainAxisAlignment(MainAxisAlignment alignment) {
    assert(alignment != null);
    if (alignment != _mainAxisAlignment) {
      _mainAxisAlignment = alignment;
      markNeedsLayout();
    }
  }

  MainAxisSize get mainAxisSize => _mainAxisSize;
  MainAxisSize _mainAxisSize;
  set mainAxisSize(MainAxisSize size) {
    assert(size != null);
    if (size != _mainAxisSize) {
      _mainAxisSize = size;
      markNeedsLayout();
    }
  }

  VerticalDirection get overflowDirection => _overflowDirection;
  VerticalDirection _overflowDirection;
  set overflowDirection(VerticalDirection direction) {
    assert(direction != null);
    if (direction != _overflowDirection) {
      _overflowDirection = direction;
      markNeedsLayout();
    }
  }

  double get overflowButtonSpacing => _overflowButtonSpacing;
  double _overflowButtonSpacing;
  set overflowButtonSpacing(double spacing) {
    if (spacing != _overflowButtonSpacing) {
      _overflowButtonSpacing = spacing;
      markNeedsLayout();
    }
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection direction) {
    assert(direction != null);
    if (direction != _textDirection) {
      _textDirection = direction;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ButtonBarParentData) {
      child.parentData = _ButtonBarParentData();
    }
  }

  // How much the column overflowed its maximum constraints vertically.
  double _overflow;

  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  @override
  void performLayout() {
    final double maxWidth = constraints.maxWidth;
    RenderBox child = firstChild;
    double totalIntrinsicWidth = 0;
    bool useColumn = false;

    // Iterate children to figure out if their intrinsic widths would overflow
    // our maxWidth, switching to a column layout if that is the case.
    while (child != null) {
      final _ButtonBarParentData childParentData = child.parentData as _ButtonBarParentData;
      final double intrinsicWidth = child.getMaxIntrinsicWidth(double.infinity);

      childParentData.intrinsicWidth = intrinsicWidth;
      totalIntrinsicWidth += intrinsicWidth;

      if (totalIntrinsicWidth > maxWidth) {
        useColumn = true;
        break;
      }

      child = childParentData.nextSibling;
    }

    if (useColumn) {
      final BoxConstraints childConstraints = BoxConstraints(
        maxWidth: maxWidth,
      );

      switch (overflowDirection) {
        case VerticalDirection.down:
          child = firstChild;
          break;
        case VerticalDirection.up:
          child = lastChild;
          break;
      }

      double currentHeight = 0.0;

      while (child != null) {
        final _ButtonBarParentData childParentData = child.parentData as _ButtonBarParentData;

        // Lay out the child with an unbounded height and the same maxWidth as
        // our incoming constraints.
        child.layout(childConstraints, parentUsesSize: true);

        // Set the cross axis alignment for the column to match the main axis
        // alignment for a row. For [MainAxisAlignment.spaceAround],
        // [MainAxisAlignment.spaceBetween] and [MainAxisAlignment.spaceEvenly]
        // cases, use [MainAxisAlignment.start].
        switch (mainAxisAlignment) {
          case MainAxisAlignment.center:
            final double midpoint = (maxWidth - child.size.width) / 2.0;
            childParentData.offset = Offset(midpoint, currentHeight);
            break;
          case MainAxisAlignment.end:
            switch (textDirection) {
              case TextDirection.ltr:
                childParentData.offset = Offset(maxWidth - child.size.width, currentHeight);
                break;
              case TextDirection.rtl:
                childParentData.offset = Offset(0, currentHeight);
                break;
            }
            break;
          default:
            switch (textDirection) {
              case TextDirection.ltr:
                childParentData.offset = Offset(0, currentHeight);
                break;
              case TextDirection.rtl:
                childParentData.offset = Offset(maxWidth - child.size.width, currentHeight);
                break;
            }
            break;
        }

        currentHeight += child.size.height;

        switch (overflowDirection) {
          case VerticalDirection.down:
            child = childParentData.nextSibling;
            break;
          case VerticalDirection.up:
            child = childParentData.previousSibling;
            break;
        }

        if (overflowButtonSpacing != null && child != null)
          currentHeight += overflowButtonSpacing;
      }

      size = constraints.constrain(Size(maxWidth, currentHeight));
      _overflow = math.max(0.0, currentHeight - constraints.maxHeight);
    } else {
      double crossSize = 0.0;
      int totalChildren = 0;

      // Lay out each child to find the row's cross axis size.
      child = firstChild;
      while (child != null) {
        final _ButtonBarParentData childParentData = child.parentData as _ButtonBarParentData;
        final double childWidth = childParentData.intrinsicWidth;
        final BoxConstraints childConstraints = BoxConstraints(
          // Give the child a tight width corresponding to its getMaxIntrinsicWidth,
          // same as if it were in an IntrinsicWidth widget.
          minWidth: childWidth,
          maxWidth: childWidth,
          maxHeight: constraints.maxHeight,
        );

        child.layout(childConstraints, parentUsesSize: true);

        crossSize = math.max(crossSize, child.size.height);
        totalChildren += 1;

        child = childParentData.nextSibling;
      }

      double mainSize;
      switch (mainAxisSize) {
        case MainAxisSize.min:
          mainSize = totalIntrinsicWidth;
          break;
        case MainAxisSize.max:
          mainSize = maxWidth;
          break;
      }
      size = constraints.constrain(Size(mainSize, crossSize));

      final double mainSizeDelta = mainSize - totalIntrinsicWidth;
      final double remainingSpace = math.max(0.0, mainSizeDelta);

      // The row shouldn't overflow because totalIntrinsicWidth <= maxWidth.
      _overflow = 0.0;

      // Whether we should position children right-to-left instead of left-to-right.
      bool flipMainAxis;
      switch (textDirection) {
        case TextDirection.ltr:
          flipMainAxis = false;
          break;
        case TextDirection.rtl:
          flipMainAxis = true;
          break;
      }

      double leadingSpace;
      double betweenSpace;

      switch (_mainAxisAlignment) {
        case MainAxisAlignment.start:
          leadingSpace = 0.0;
          betweenSpace = 0.0;
          break;
        case MainAxisAlignment.end:
          leadingSpace = remainingSpace;
          betweenSpace = 0.0;
          break;
        case MainAxisAlignment.center:
          leadingSpace = remainingSpace / 2.0;
          betweenSpace = 0.0;
          break;
        case MainAxisAlignment.spaceBetween:
          leadingSpace = 0.0;
          betweenSpace = totalChildren > 1 ? remainingSpace / (totalChildren - 1) : 0.0;
          break;
        case MainAxisAlignment.spaceAround:
          betweenSpace = totalChildren > 0 ? remainingSpace / totalChildren : 0.0;
          leadingSpace = betweenSpace / 2.0;
          break;
        case MainAxisAlignment.spaceEvenly:
          betweenSpace = totalChildren > 0 ? remainingSpace / (totalChildren + 1) : 0.0;
          leadingSpace = betweenSpace;
          break;
      }

      // Position children according to the mainAxisAlignment.
      double childMainPosition = flipMainAxis ? maxWidth - leadingSpace : leadingSpace;
      child = firstChild;
      while (child != null) {
        final _ButtonBarParentData childParentData = child.parentData as _ButtonBarParentData;

        if (flipMainAxis) {
          childMainPosition -= child.size.width;
        }

        // Vertically center the child.
        childParentData.offset = Offset(childMainPosition, crossSize / 2.0 - child.size.height / 2.0);

        if (flipMainAxis) {
          childMainPosition -= betweenSpace;
        } else {
          childMainPosition += child.size.width + betweenSpace;
        }

        child = childParentData.nextSibling;
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    context.pushClipRect(needsCompositing, offset, Offset.zero & size, defaultPaint, clipBehavior: Clip.hardEdge);

    assert(() {
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorHint(
          'This can happen if the ButtonBar was given a constrained height and '
          'needed to lay out its children vertically.'
        ),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      final Rect overflowChildRect = Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
      paintOverflowIndicator(context, offset, Offset.zero & size, overflowChildRect, overflowHints: debugOverflowHints);

      return true;
    }());
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (_overflow is double && _hasOverflow)
      header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment, defaultValue: MainAxisAlignment.end));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize, defaultValue: MainAxisSize.max));
    properties.add(EnumProperty<VerticalDirection>('overflowDirection', overflowDirection, defaultValue: VerticalDirection.down));
    properties.add(DoubleProperty('overflowButtonSpacing', overflowButtonSpacing, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}

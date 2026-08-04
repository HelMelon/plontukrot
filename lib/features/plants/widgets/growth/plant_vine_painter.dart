import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_colors.dart';

/// Snake vine under the plant photo.
///
/// First row is opaque in the foreground. Further rows fade and sit behind
/// [belowFirstRow] (counter / info). Leaves: [HugeIcons.strokeRoundedLeaf01],
/// max 8 per row, alternating above/below, snake wrap with rounded U-turns.
class PlantVineStrip extends StatelessWidget {
  static const int maxLeavesPerRow = 8;
  static const double leafSize = 30;
  static const double rowHeight = 56;
  static const double overflowOpacity = 0.32;

  final int leafCount;

  /// Content placed after the first vine row, above overflow rows (background).
  final Widget? belowFirstRow;

  const PlantVineStrip({
    super.key,
    required this.leafCount,
    this.belowFirstRow,
  });

  @override
  Widget build(BuildContext context) {
    final count = leafCount < 0 ? 0 : leafCount;
    final rows =
        count == 0 ? 1 : ((count + maxLeavesPerRow - 1) ~/ maxLeavesPerRow);

    Widget rowAt(int row, {required double opacity}) {
      return Opacity(
        opacity: opacity,
        child: SizedBox(
          height: rowHeight,
          width: double.infinity,
          child: _VineRow(
            rowIndex: row,
            leafStartIndex: row * maxLeavesPerRow,
            leafCountInRow: count == 0
                ? 0
                : math.min(maxLeavesPerRow, count - row * maxLeavesPerRow),
            totalRows: rows,
          ),
        ),
      );
    }

    final overflow = rows <= 1
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var row = 1; row < rows; row++)
                rowAt(row, opacity: overflowOpacity),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rowAt(0, opacity: 1),
        if (overflow != null || belowFirstRow != null)
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              if (overflow != null) overflow,
              if (belowFirstRow != null) belowFirstRow!,
            ],
          ),
      ],
    );
  }
}

class _VineRow extends StatelessWidget {
  final int rowIndex;
  final int leafStartIndex;
  final int leafCountInRow;
  final int totalRows;

  const _VineRow({
    required this.rowIndex,
    required this.leafStartIndex,
    required this.leafCountInRow,
    required this.totalRows,
  });

  bool get _rtl => rowIndex.isOdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / PlantVineStrip.maxLeavesPerRow;
        final hasNext = rowIndex < totalRows - 1;
        final connectRight = !_rtl && hasNext;
        final connectLeft = _rtl && hasNext;
        final fromRightTurn = _rtl && rowIndex > 0;
        final fromLeftTurn = !_rtl && rowIndex > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SnakeStemPainter(
                  rtl: _rtl,
                  connectDownOnRight: connectRight,
                  connectDownOnLeft: connectLeft,
                  startFromRightTurn: fromRightTurn,
                  startFromLeftTurn: fromLeftTurn,
                ),
              ),
            ),
            for (var j = 0; j < leafCountInRow; j++)
              _buildLeaf(
                absoluteIndex: leafStartIndex + j,
                positionInRow: j,
                cellWidth: cellW,
              ),
          ],
        );
      },
    );
  }

  Widget _buildLeaf({
    required int absoluteIndex,
    required int positionInRow,
    required double cellWidth,
  }) {
    final column = _rtl
        ? (PlantVineStrip.maxLeavesPerRow - 1 - positionInRow)
        : positionInRow;
    final above = absoluteIndex.isEven;
    final isFresh = absoluteIndex >= leafStartIndex + leafCountInRow - 2;

    return Positioned(
      left: column * cellWidth + (cellWidth - PlantVineStrip.leafSize) / 2,
      top: above ? 2 : PlantVineStrip.rowHeight - PlantVineStrip.leafSize - 2,
      child: Transform.flip(
        flipY: !above,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedLeaf01,
          size: PlantVineStrip.leafSize,
          color: isFresh ? AppColors.goldAccent : AppColors.accentLight,
          strokeWidth: 1.8,
        ),
      ),
    );
  }
}

class _SnakeStemPainter extends CustomPainter {
  final bool rtl;
  final bool connectDownOnRight;
  final bool connectDownOnLeft;
  final bool startFromRightTurn;
  final bool startFromLeftTurn;

  const _SnakeStemPainter({
    required this.rtl,
    required this.connectDownOnRight,
    required this.connectDownOnLeft,
    required this.startFromRightTurn,
    required this.startFromLeftTurn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_stemPath(size), paint);
  }

  Path _stemPath(Size size) {
    final midY = size.height * 0.5;
    final turnR = size.height * 0.5;
    final leftX = turnR;
    final rightX = size.width - turnR;
    final amplitude = size.height * 0.18;

    final path = Path();

    if (rtl) {
      // Enter from previous U-turn at the right, or start at right edge.
      if (startFromRightTurn) {
        path.moveTo(rightX, midY);
      } else {
        path.moveTo(size.width, midY);
        path.lineTo(rightX, midY);
      }

      _appendWave(
        path,
        fromX: rightX,
        toX: leftX,
        midY: midY,
        amplitude: amplitude,
        leftToRight: false,
      );

      if (connectDownOnLeft) {
        // Rounded U-turn down onto the next row (continues below this row).
        path.arcToPoint(
          Offset(leftX, size.height + midY),
          radius: Radius.circular(turnR),
          clockwise: false,
        );
      } else {
        path.lineTo(0, midY);
      }
    } else {
      if (startFromLeftTurn) {
        path.moveTo(leftX, midY);
      } else {
        path.moveTo(0, midY);
        path.lineTo(leftX, midY);
      }

      _appendWave(
        path,
        fromX: leftX,
        toX: rightX,
        midY: midY,
        amplitude: amplitude,
        leftToRight: true,
      );

      if (connectDownOnRight) {
        path.arcToPoint(
          Offset(rightX, size.height + midY),
          radius: Radius.circular(turnR),
          clockwise: true,
        );
      } else {
        path.lineTo(size.width, midY);
      }
    }

    return path;
  }

  void _appendWave(
    Path path, {
    required double fromX,
    required double toX,
    required double midY,
    required double amplitude,
    required bool leftToRight,
  }) {
    final span = toX - fromX;
    final dir = leftToRight ? 1.0 : -1.0;
    // Three gentle waves between turn anchors.
    path.cubicTo(
      fromX + span * 0.2,
      midY - amplitude * dir,
      fromX + span * 0.3,
      midY + amplitude * dir,
      fromX + span * 0.5,
      midY,
    );
    path.cubicTo(
      fromX + span * 0.7,
      midY - amplitude * dir,
      fromX + span * 0.8,
      midY + amplitude * dir,
      toX,
      midY,
    );
  }

  @override
  bool shouldRepaint(covariant _SnakeStemPainter oldDelegate) {
    return oldDelegate.rtl != rtl ||
        oldDelegate.connectDownOnRight != connectDownOnRight ||
        oldDelegate.connectDownOnLeft != connectDownOnLeft ||
        oldDelegate.startFromRightTurn != startFromRightTurn ||
        oldDelegate.startFromLeftTurn != startFromLeftTurn;
  }
}

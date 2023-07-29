import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:skribble_clone/features/paint/data/remote/models/touch_points.dart';

class MyCustomPinter extends CustomPainter {
  List<TouchPoints?> pointList;
  List<Offset> offSetPoints = [];

  MyCustomPinter({required this.pointList});

  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = Colors.white;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, background);
    canvas.clipRect(rect);
    // TODO: implement paint

    //  Logic for points, if there a point, we need to display point
    //  if there is line, we need to connect the points

    for (int i = 0; i < pointList.length - 1; i++) {
      if (pointList[i] != null && pointList[i + 1] != null) {
        //This is a line
        canvas.drawLine(pointList[i]!.points, pointList[i + 1]!.points, pointList[i]!.paint);
      } else if (pointList[i] != null && pointList[i + 1] == null) {
        //  This is a point
        offSetPoints.clear();
        offSetPoints.add(pointList[i]!.points);
        offSetPoints.add(Offset(pointList[i]!.points.dx + 0.1, pointList[i]!.points.dy + 0.1));
        canvas.drawPoints(ui.PointMode.points, offSetPoints, pointList[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

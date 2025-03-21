// Пример: graph_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../db.dart';
import '../desine/colors.dart';
import 'PointData.dart';

class GraphView extends StatefulWidget {
  const GraphView({Key? key}) : super(key: key);

  @override
  _GraphViewState createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  List<PointData> pointsData = [];
  List<List<int>>? _cachedFaces;
  double rotationX = 0.0;
  double rotationY = 0.0;
  double _scale = 1.0;
  double _initialScale = 1.0;
  int? _selectedPointIndex;

  static const double minScale = 0.05;
  static const double maxScale = 5;

  late Future<void> _pointsFuture;

  @override
  void initState() {
    super.initState();
    // Загружаем точки и вычисляем кэш граней.
    _pointsFuture = DB.fetchPoints().then((_) {
      if (!mounted) return;
      setState(() {
        pointsData = DB.getPoints();
        _cachedFaces = _computeFaces(pointsData.length);
      });
    });
  }

  // Добавляем функцию обновления графа
  void _refreshGraph() async {
    await DB.fetchPoints();
    setState(() {
      pointsData = DB.getPoints();
      _cachedFaces = _computeFaces(pointsData.length);
    });
  }

  List<List<int>> _computeFaces(int n) {
    List<List<int>> faces = [];
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        for (int k = j + 1; k < n; k++) {
          faces.add([i, j, k]);
        }
      }
    }
    return faces;
  }

  void _onScaleStart(ScaleStartDetails details) {
    _initialScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!mounted) return;
    setState(() {
      rotationY += details.focalPointDelta.dx * 0.01;
      rotationX -= details.focalPointDelta.dy * 0.01;
      _scale = (_initialScale * details.scale).clamp(minScale, maxScale);
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && mounted) {
      setState(() {
        _scale = (_scale * (1 - event.scrollDelta.dy * 0.001)).clamp(minScale, maxScale);
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    const Size size = Size(300, 300);
    List<vmath.Vector3> points =
    pointsData.map((p) => vmath.Vector3(p.x, p.y, p.z)).toList();

    if (points.isNotEmpty) {
      final center = points.reduce((a, b) => a + b) / points.length.toDouble();
      points = points.map((p) => p - center).toList();
    }

    var transform = vmath.Matrix4.identity();
    transform.scale(_scale);
    transform.rotateX(rotationX);
    transform.rotateY(rotationY);
    List<vmath.Vector3> transformedPoints = points.map(transform.transform3).toList();
    List<Offset> projectedPoints =
    transformedPoints.map((p) => _projectPoint(p, size)).toList();
    const double threshold = 10.0;
    int? tappedIndex;
    for (int i = 0; i < projectedPoints.length; i++) {
      if ((projectedPoints[i] - details.localPosition).distance < threshold) {
        tappedIndex = i;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedPointIndex = tappedIndex;
    });
  }

  Offset _projectPoint(vmath.Vector3 point, Size size) {
    const double perspective = 5;
    final double baseScale = size.width / 4;
    final double zFactor = perspective / (perspective - point.z);
    return Offset(
      point.x * zFactor * baseScale + size.width / 2,
      point.y * zFactor * baseScale + size.height / 2,
    );
  }

  @override
  void dispose() {
    // Отмена отложенных задач или подписок, если они добавятся.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _pointsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          pointsData = DB.getPoints();
          return Center(
            child: Listener(
              onPointerSignal: _onPointerSignal,
              child: RepaintBoundary(
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  child: CustomPaint(
                    painter: Graph3DPainter(
                      pointsData: pointsData,
                      rotationX: rotationX,
                      rotationY: rotationY,
                      scale: _scale,
                      selectedPointIndex: _selectedPointIndex,
                      cachedFaces: _cachedFaces,
                    ),
                    size: const Size(300, 300),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}


class Graph3DPainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final double scale;
  final List<PointData> pointsData;
  final int? selectedPointIndex;
  final List<List<int>>? cachedFaces;

  Graph3DPainter({
    required this.pointsData,
    required this.rotationX,
    required this.rotationY,
    required this.scale,
    this.selectedPointIndex,
    this.cachedFaces,
  });

  Offset project(vmath.Vector3 point, Size size) {
    const double perspective = 5;
    final double baseScale = size.width / 4;
    final double zFactor = perspective / (perspective - point.z);
    return Offset(
      point.x * zFactor * baseScale + size.width / 2,
      point.y * zFactor * baseScale + size.height / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pointsData.isEmpty) return;

    List<vmath.Vector3> points =
    pointsData.map((p) => vmath.Vector3(p.x, p.y, p.z)).toList();
    if (points.isNotEmpty) {
      final center = points.reduce((a, b) => a + b) / points.length.toDouble();
      points = points.map((p) => p - center).toList();
    }

    var transform = vmath.Matrix4.identity();
    transform.scale(scale);
    transform.rotateX(rotationX);
    transform.rotateY(rotationY);
    List<vmath.Vector3> transformedPoints =
    points.map(transform.transform3).toList();

    double minZ = transformedPoints.map((p) => p.z).reduce((a, b) => a < b ? a : b);
    double maxZ = transformedPoints.map((p) => p.z).reduce((a, b) => a > b ? a : b);
    List<Offset> projectedPoints =
    transformedPoints.map((p) => project(p, size)).toList();
    List<double> normalizedFactors =
    transformedPoints.map((p) => (p.z - minZ) / (maxZ - minZ)).toList();

    List<List<int>> faces = cachedFaces ?? _computeAllFaces(transformedPoints.length);

    faces.sort((a, b) {
      double avgA = (transformedPoints[a[0]].z +
          transformedPoints[a[1]].z +
          transformedPoints[a[2]].z) /
          3;
      double avgB = (transformedPoints[b[0]].z +
          transformedPoints[b[1]].z +
          transformedPoints[b[2]].z) /
          3;
      return avgA.compareTo(avgB);
    });

    for (var tri in faces) {
      Path path = Path()
        ..moveTo(projectedPoints[tri[0]].dx, projectedPoints[tri[0]].dy)
        ..lineTo(projectedPoints[tri[1]].dx, projectedPoints[tri[1]].dy)
        ..lineTo(projectedPoints[tri[2]].dx, projectedPoints[tri[2]].dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = plane
          ..style = PaintingStyle.fill,
      );
    }

    for (var tri in faces) {
      for (var edge in [
        [tri[0], tri[1]],
        [tri[1], tri[2]],
        [tri[2], tri[0]]
      ]) {
        bool isHighlighted = selectedPointIndex != null &&
            (edge[0] == selectedPointIndex || edge[1] == selectedPointIndex);
        Paint linePaint = Paint()
          ..color = isHighlighted ? highlighted_color : edgeNearColor
          ..strokeWidth = 1.0;
        canvas.drawLine(
            projectedPoints[edge[0]], projectedPoints[edge[1]], linePaint);
      }
    }

    const double minPointRadius = 3.0;
    const double maxPointRadius = 10.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < projectedPoints.length; i++) {
      double norm = normalizedFactors[i];
      double pointRadius =
          minPointRadius + (maxPointRadius - minPointRadius) * norm;
      Color pointColor = Color.lerp(
          pointsData[i].color, Colors.white, 0.2 * (1 - norm))!;
      final Paint pointPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(projectedPoints[i], pointRadius, pointPaint);
      final textSpan = TextSpan(
        text: pointsData[i].articleTitle,
        style: TextStyle(color: pointColor, fontSize: 12),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, projectedPoints[i] + const Offset(8, -8));
    }
  }

  List<List<int>> _computeAllFaces(int n) {
    List<List<int>> faces = [];
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        for (int k = j + 1; k < n; k++) {
          faces.add([i, j, k]);
        }
      }
    }
    return faces;
  }

  @override
  bool shouldRepaint(covariant Graph3DPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.scale != scale ||
        oldDelegate.pointsData != pointsData ||
        oldDelegate.selectedPointIndex != selectedPointIndex;
  }
}

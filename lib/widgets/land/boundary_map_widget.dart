import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/land_parcel.dart';

class BoundaryMapWidget extends StatelessWidget {
  final LandBoundary boundary;
  final bool interactive;

  const BoundaryMapWidget(
      {super.key, required this.boundary, this.interactive = true});

  @override
  Widget build(BuildContext context) {
    final center = boundary.centroid;
    return FlutterMap(
      options: MapOptions(
          initialCenter: center,
          initialZoom: 15,
          interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none)),
      children: [
        TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'cm.kamer.sync'),
        PolygonLayer(polygons: [
          Polygon(
              points: boundary.points,
              color: AppColors.primary.withValues(alpha: 0.2),
              borderColor: AppColors.primary,
              borderStrokeWidth: 2)
        ]),
      ],
    );
  }
}

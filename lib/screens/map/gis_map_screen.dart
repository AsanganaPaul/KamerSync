import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/land_parcel.dart';
import '../../providers/land_provider.dart';
import '../../services/land_service.dart';

class GisMapScreen extends ConsumerStatefulWidget {
  const GisMapScreen({super.key});

  @override
  ConsumerState<GisMapScreen> createState() => _GisMapScreenState();
}

class _GisMapScreenState extends ConsumerState<GisMapScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _drawingPoints = [];
  bool _isDrawingMode = false;
  LandParcel? _selectedParcel;
  String _mapLayer = 'streets'; // 'streets' | 'satellite'

  // Cameroon center
  static const LatLng _cameroonCenter = LatLng(3.848, 11.502);

  @override
  Widget build(BuildContext context) {
    final parcelsAsync = ref.watch(allLandParcelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS Land Map'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Map layer toggle
          IconButton(
            onPressed: () => setState(() {
              _mapLayer = _mapLayer == 'streets' ? 'satellite' : 'streets';
            }),
            icon: Icon(
              _mapLayer == 'streets' ? Icons.satellite_alt : Icons.map_outlined,
              color: Colors.white,
            ),
            tooltip: 'Toggle Map Layer',
          ),
          // Drawing mode
          IconButton(
            onPressed: () => setState(() {
              _isDrawingMode = !_isDrawingMode;
              if (!_isDrawingMode) _drawingPoints.clear();
            }),
            icon: Icon(
              _isDrawingMode ? Icons.edit_off : Icons.edit_location_alt,
              color: _isDrawingMode ? AppColors.accentLight : Colors.white,
            ),
            tooltip: 'Draw Boundary',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          parcelsAsync.when(
            data: (parcels) => GestureDetector(
              onTapUp: _isDrawingMode
                  ? (details) {
                      // Would convert to LatLng via MapController in production
                      // For demo, add approximate points
                      final center = _mapController.camera.center;
                      setState(() {
                        _drawingPoints.add(
                          LatLng(
                            center.latitude + (_drawingPoints.length * 0.001),
                            center.longitude + (_drawingPoints.length * 0.001),
                          ),
                        );
                      });
                    }
                  : null,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _cameroonCenter,
                  initialZoom: 6.5,
                  minZoom: 4,
                  maxZoom: 18,
                ),
                children: [
                  // Tile layer
                  TileLayer(
                    urlTemplate: _mapLayer == 'streets'
                        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                        : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'cm.kamer.sync',
                  ),

                  // Land parcel polygons
                  PolygonLayer(
                    polygons: parcels
                        .where(
                      (p) =>
                          p.boundary != null && p.boundary!.points.length >= 3,
                    )
                        .map((p) {
                      final isSelected = _selectedParcel?.id == p.id;
                      return Polygon(
                        points: p.boundary!.points,
                        color: _statusColor(
                          p.status,
                        ).withOpacity(isSelected ? 0.5 : 0.25),
                        borderColor: _statusColor(p.status),
                        borderStrokeWidth: isSelected ? 3 : 2,
                      );
                    }).toList(),
                  ),

                  // Drawing polygon
                  if (_drawingPoints.length >= 2)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _drawingPoints,
                          color: AppColors.accent.withOpacity(0.3),
                          borderColor: AppColors.accent,
                          borderStrokeWidth: 2.5,
                        ),
                      ],
                    ),

                  // Parcel markers
                  MarkerLayer(
                    markers: parcels.where((p) => p.boundary != null).map((p) {
                      final centroid = p.boundary!.centroid;
                      return Marker(
                        point: centroid,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedParcel = p),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _statusColor(p.status),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.landscape,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          // Drawing mode indicator
          if (_isDrawingMode)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_location_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Drawing Mode: ${_drawingPoints.length} points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_drawingPoints.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _drawingPoints.clear()),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Selected parcel info card
          if (_selectedParcel != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _ParcelInfoCard(
                parcel: _selectedParcel!,
                onClose: () => setState(() => _selectedParcel = null),
                onView: () =>
                    context.push('/land/detail/${_selectedParcel!.id}'),
              ),
            ),

          // Map legend
          Positioned(
            bottom: _selectedParcel != null ? 200 : 20,
            right: 16,
            child: _buildLegend(),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            top: 80,
            child: Column(
              children: [
                _mapControl(Icons.add, () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                }),
                const SizedBox(height: 4),
                _mapControl(Icons.remove, () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                }),
                const SizedBox(height: 4),
                _mapControl(Icons.my_location, () {
                  _mapController.move(_cameroonCenter, 6.5);
                }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isDrawingMode && _drawingPoints.length >= 3
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(
                  AppRoutes.landRegistration,
                  extra: List<LatLng>.from(_drawingPoints),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Use Boundary'),
              backgroundColor: AppColors.success,
            )
          : null,
    );
  }

  Widget _mapControl(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
          const SizedBox(height: 6),
          _legendItem('Approved', AppColors.success),
          _legendItem('Pending', AppColors.warning),
          _legendItem('Under Review', AppColors.info),
          _legendItem('Rejected', AppColors.error),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.4),
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(LandStatus status) {
    switch (status) {
      case LandStatus.approved:
        return AppColors.success;
      case LandStatus.pending:
        return AppColors.warning;
      case LandStatus.underReview:
        return AppColors.info;
      case LandStatus.rejected:
        return AppColors.error;
      case LandStatus.transferred:
        return AppColors.primaryLight;
    }
  }
}

class _ParcelInfoCard extends StatelessWidget {
  final LandParcel parcel;
  final VoidCallback onClose;
  final VoidCallback onView;

  const _ParcelInfoCard({
    required this.parcel,
    required this.onClose,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  parcel.landId ?? 'Application Pending',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  parcel.ownerName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  parcel.address,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

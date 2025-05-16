import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  mp.MapboxMap? mapboxcontroller;
  StreamSubscription<gl.Position>? userPositionStream;
  mp.PointAnnotationManager? pointAnnotationManager;

  @override
  void initState() {
    super.initState();
    _setupPositionTracking();
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: mp.MapWidget(
        onMapCreated: _onMapCreated,
        styleUri: mp.MapboxStyles.LIGHT,
      ),
    );
  }

  void _onMapCreated(mp.MapboxMap controller) async {
    mapboxcontroller = controller;

    await mapboxcontroller?.location.updateSettings(
      mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    pointAnnotationManager =
        await mapboxcontroller?.annotations.createPointAnnotationManager();

    final Uint8List imageData = await loadHQMarkerImage();

    // Пример добавления маркера на карту (можно удалить, если маркер будет ставиться по пользователю)
    pointAnnotationManager?.create(
      mp.PointAnnotationOptions(
        geometry: mp.Point(coordinates: mp.Position(72.7831, 42.8996)),
        image: imageData,
        iconSize: 1.5,
      ),
    );
  }

  Future<void> _setupPositionTracking() async {
    bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Службы определения местоположения отключены');
    }

    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        return Future.error('Служба определения местоположения отказано');
      }
    }

    if (permission == gl.LocationPermission.deniedForever) {
      return Future.error(
        'Разрешения на определение местоположения постоянно отклонены, мы не можем запрашивать разрешения',
      );
    }

    gl.LocationSettings locationSettings = gl.LocationSettings(
      accuracy: gl.LocationAccuracy.high,
      distanceFilter: 100,
    );

    userPositionStream?.cancel();
    userPositionStream = gl.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((gl.Position? position) async {
      if (position != null && mapboxcontroller != null) {
        mapboxcontroller?.setCamera(
          mp.CameraOptions(
            zoom: 15,
            center: mp.Point(
              coordinates: mp.Position(position.longitude, position.latitude),
            ),
          ),
        );

        final Uint8List imageData = await loadHQMarkerImage();

        // Очистить предыдущие аннотации и добавить новую
        await pointAnnotationManager?.deleteAll();
        pointAnnotationManager?.create(
          mp.PointAnnotationOptions(
            geometry: mp.Point(coordinates: mp.Position(76.889639, 43.286865)),
            image: imageData,
            iconSize: 0.1,
          ),
        );
        await pointAnnotationManager?.create(
          mp.PointAnnotationOptions(
            geometry: mp.Point(coordinates: mp.Position(76.866856, 43.204548)),
            image: imageData,
            iconSize: 0.1,
          ),
        );
        await pointAnnotationManager?.create(
          mp.PointAnnotationOptions(
            geometry: mp.Point(coordinates: mp.Position(76.839328,43.238925)),
            image: imageData,
            iconSize: 0.1,
          ),
        );
        await pointAnnotationManager?.create(
          mp.PointAnnotationOptions(
            geometry: mp.Point(coordinates: mp.Position(76.880259, 43.202955)),
            image: imageData,
            iconSize: 0.1,
          ),
        );
      }
    });
  }

  Future<Uint8List> loadHQMarkerImage() async {
    final byteData = await rootBundle.load("assets/icons/zaman.png");
    return byteData.buffer.asUint8List();
  }
}

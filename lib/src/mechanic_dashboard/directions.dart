// ignore_for_file: prefer_const_constructors, unused_field, avoid_function_literals_in_foreach_calls, unused_import, await_only_futures, avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myapp/.env.dart';

class Directions extends StatefulWidget {
  const Directions({super.key});

  @override
  State<Directions> createState() => _DirectionsState();
}

class _DirectionsState extends State<Directions> {
  final Completer<GoogleMapController> _controller = Completer();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final CollectionReference _jobs =
      FirebaseFirestore.instance.collection('Jobs');

  String? userEmail;
  double? lat = 0;
  double? lng = 0;
  LatLng destination = LatLng(0, 0);

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;
  LocationData? sourceLocation;
  bool polylineLoaded = false;

  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    userEmail = auth.currentUser?.email;
    getDriverLocation();
    setCustomMarkerIcon();
  }

  Future<void> getDriverLocation() async {
    if (userEmail == null) return;

    final QuerySnapshot requestsQuery = await _jobs
        .where("mechanicEmail", isEqualTo: userEmail)
        .where("jobRequestStatus", isEqualTo: "accepted")
        .get();

    if (requestsQuery.docs.isNotEmpty) {
      final doc = requestsQuery.docs.first;
      lat = doc['latitude'].toDouble();
      lng = doc['longitude'].toDouble();
      destination = LatLng(lat!, lng!);
      getCurrentLocation();
    }
  }

  Future<void> getCurrentLocation() async {
    final Location location = Location();
    sourceLocation = await location.getLocation();
    if (sourceLocation != null) {
      getPolyPoints();
    }

    location.onLocationChanged.listen((newLocation) async {
      currentLocation = newLocation;
      updateMechanicLocation(newLocation);

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> updateMechanicLocation(LocationData newLocation) async {
    if (userEmail == null) return;

    final QuerySnapshot requestsQuery = await _jobs
        .where("mechanicEmail", isEqualTo: userEmail)
        .where("jobRequestStatus", isEqualTo: "accepted")
        .get();

    if (requestsQuery.docs.isNotEmpty) {
      final json = {
        'mechanicLat': newLocation.latitude,
        'mechanicLng': newLocation.longitude,
      };

      final docId = requestsQuery.docs.first.id;
      await _jobs.doc(docId).update(json);
    }
  }

  Future<void> getPolyPoints() async {
    if (lat != 0 && sourceLocation != null) {
      final PolylinePoints polylinePoints = PolylinePoints();

      final PolylineResult result =
          await polylinePoints.getRouteBetweenCoordinates(
        "AIzaSyBKQobKPYoGeFjC6u9uirCE1fDj2n8W0Tw",
        PointLatLng(sourceLocation!.latitude!, sourceLocation!.longitude!),
        PointLatLng(destination.latitude, destination.longitude),
        travelMode: TravelMode.driving,
      );

      if (result.points.isNotEmpty) {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        polylineLoaded = true;
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> setCustomMarkerIcon() async {
    currentLocationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/images/driver_icon_maps_icon.jpg");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff24688e)),
        toolbarHeight: 75,
        leadingWidth: 75,
      ),
      body: currentLocation == null ||
              sourceLocation == null ||
              lat == 0 ||
              !polylineLoaded
          ? const Center(child: Text('Loading'))
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
                zoom: 15,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: polylineCoordinates,
                  color: Colors.blue,
                  width: 6,
                )
              },
              markers: {
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  icon: currentLocationIcon,
                  position: LatLng(
                      currentLocation!.latitude!, currentLocation!.longitude!),
                ),
                Marker(
                  markerId: const MarkerId('source'),
                  position: LatLng(
                      sourceLocation!.latitude!, sourceLocation!.longitude!),
                ),
                Marker(
                  markerId: const MarkerId('destination'),
                  position: destination,
                ),
              },
              onMapCreated: (mapController) {
                _controller.complete(mapController);
              },
            ),
    );
  }
}

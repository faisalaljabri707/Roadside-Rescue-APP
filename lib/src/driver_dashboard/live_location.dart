// ignore_for_file: prefer_const_constructors, unused_field, avoid_function_literals_in_foreach_calls, unused_import, await_only_futures, avoid_print, prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myapp/.env.dart';

class LiveLocation extends StatefulWidget {
  const LiveLocation({super.key});

  @override
  State<LiveLocation> createState() => _LiveLocationState();
}

class _LiveLocationState extends State<LiveLocation> {
  final Completer<GoogleMapController> _controller = Completer();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final CollectionReference _jobs =
      FirebaseFirestore.instance.collection('Jobs');

  String? userEmail;
  double? lat = 1;
  double? lng = 1;
  LatLng sourceLocation = LatLng(1, 1);
  LatLng? currentLocation;
  LocationData? destination;

  List<LatLng> polylineCoordinates = [];
  bool polylineLoaded = false;
  bool sourceLocationLoaded = false;

  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    userEmail = auth.currentUser?.email;
    getMechanicLocation();
    setCustomMarkerIcon();
  }

  Future<void> getMechanicLocation() async {
    if (userEmail == null) return;

    try {
      final QuerySnapshot requestsQuery = await _jobs
          .where("driverEmail", isEqualTo: userEmail)
          .where("jobRequestStatus", isEqualTo: "accepted")
          .get();

      if (requestsQuery.docs.isNotEmpty) {
        final doc = requestsQuery.docs.first;
        lat = doc['mechanicLat'].toDouble();
        lng = doc['mechanicLng'].toDouble();
        sourceLocation = LatLng(lat!, lng!);
        sourceLocationLoaded = true;
        startLiveLocationUpdates();
        getLocation();
      }
    } catch (e) {
      // Handle the index error gracefully here
      print('Error fetching mechanic location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error fetching mechanic location. Please try again later.')),
      );
    }
  }

  Future<void> startLiveLocationUpdates() async {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final QuerySnapshot requestsQuery = await _jobs
            .where("driverEmail", isEqualTo: userEmail)
            .where("jobRequestStatus", isEqualTo: "accepted")
            .get();

        if (requestsQuery.docs.isNotEmpty) {
          final doc = requestsQuery.docs.first;
          lat = doc['mechanicLat'].toDouble();
          lng = doc['mechanicLng'].toDouble();
          currentLocation = LatLng(lat!, lng!);
          if (mounted) {
            setState(() {});
          }
        } else {
          timer.cancel();
        }
      } catch (e) {
        // Handle the error gracefully
        print('Error updating live location: $e');
      }
    });
  }

  Future<void> getLocation() async {
    final Location location = Location();
    destination = await location.getLocation();
    if (destination != null) {
      getPolyPoints();
    }
  }

  Future<void> getPolyPoints() async {
    if (sourceLocationLoaded && destination != null) {
      final PolylinePoints polylinePoints = PolylinePoints();

      final PolylineResult result =
          await polylinePoints.getRouteBetweenCoordinates(
        "AIzaSyBKQobKPYoGeFjC6u9uirCE1fDj2n8W0Tw", // Replace with your actual API key
        PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
        PointLatLng(destination!.latitude!, destination!.longitude!),
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
      body: currentLocation == null || !sourceLocationLoaded || !polylineLoaded
          ? const Center(child: Text('Loading'))
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(destination!.latitude!, destination!.longitude!),
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
                  position: currentLocation!,
                ),
                Marker(
                  markerId: const MarkerId('source'),
                  position: sourceLocation,
                ),
                Marker(
                  markerId: const MarkerId('destination'),
                  position:
                      LatLng(destination!.latitude!, destination!.longitude!),
                ),
              },
              onMapCreated: (mapController) {
                _controller.complete(mapController);
              },
            ),
    );
  }
}

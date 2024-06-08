import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/src/widgets/bottom_nav_driver.dart';

class NearestMechanics extends StatefulWidget {
  const NearestMechanics({Key? key}) : super(key: key);

  @override
  State<NearestMechanics> createState() => _NearestMechanicsState();
}

class _NearestMechanicsState extends State<NearestMechanics> {
  final CollectionReference _mechanics =
      FirebaseFirestore.instance.collection('Mechanics');
  final CollectionReference _jobs =
      FirebaseFirestore.instance.collection('Jobs');
  LocationData? currentLocation;
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;
  double dis = 0;
  String mecEmail = "";

  @override
  void initState() {
    super.initState();
    _getNearestMechanics();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    currentLocation = await location.getLocation();
  }

  Future<void> _getNearestMechanics() async {
    await _getCurrentLocation();
    if (currentLocation == null) return;

    QuerySnapshot requestsQuery = await _mechanics.get();

    for (var document in requestsQuery.docs) {
      double distance = Geolocator.distanceBetween(
        document['lat'],
        document['lng'],
        currentLocation!.latitude!,
        currentLocation!.longitude!,
      );
      distance = double.parse((distance / 1000).toStringAsExponential(2));

      await _mechanics.doc(document.id).update({'distance': distance});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff24688e)),
        toolbarHeight: 75,
        leadingWidth: 75,
      ),
      bottomNavigationBar: BottomNavDriverWidget(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Available Rescuers near you',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Gabriela-Regular",
                ),
              ),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: _mechanics.orderBy('distance').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>?;

                      return Card(
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        color: const Color.fromARGB(255, 215, 193, 226),
                        child: ListTile(
                          leading: const Icon(Icons.person_2_rounded, size: 45),
                          title: Text(
                            data?['fname'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "Ratings: ${data?.containsKey('rating') == true ? data!['rating'] : 'N/A'} \nDistance: ${data?['distance'] ?? 'N/A'} KM",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          isThreeLine: true,
                          iconColor: Colors.blueGrey,
                          onTap: () async {
                            QuerySnapshot jobQuery = await _jobs
                                .where("mechanicEmail",
                                    isEqualTo: data?['email'])
                                .where("jobRequestStatus",
                                    whereIn: ["requested", "accepted"]).get();

                            if (jobQuery.docs.isEmpty) {
                              if (currentLocation != null &&
                                  userEmail != null) {
                                QuerySnapshot mechanicQuery = await _mechanics
                                    .where("email", isEqualTo: data?['email'])
                                    .get();

                                if (mechanicQuery.docs.isNotEmpty) {
                                  mecEmail = mechanicQuery.docs.first['email'];

                                  final json = {
                                    'driverEmail': userEmail,
                                    'mechanicEmail': mecEmail,
                                    'jobRequestStatus': 'requested',
                                    'latitude': currentLocation!.latitude,
                                    'longitude': currentLocation!.longitude,
                                    'distance': dis,
                                    'date': DateTime.now()
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0],
                                    'time':
                                        "${DateTime.now().hour} : ${DateTime.now().minute}",
                                    'rating': null,
                                    'feedback': null,
                                    'fee': null
                                  };

                                  await _jobs.doc().set(json);
                                }
                                // ignore: use_build_context_synchronously
                                GoRouter.of(context).push('/driver');
                              }
                            } else {
                              print('Request already sent');
                            }
                          },
                        ),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }
}

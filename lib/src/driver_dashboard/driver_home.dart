// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_print, dead_code, unrelated_type_equality_checks, prefer_is_empty, use_build_context_synchronously, unnecessary_string_interpolations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/src/widgets/bottom_nav_driver.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? currentUser;
  String? userEmail;
  String? mecEmail;
  String? driverEmail;
  String? fee;
  String? userName;
  int ratingVal = 0;

  final ratingController = TextEditingController();
  String? status;
  String docId = "";
  final CollectionReference _jobs =
      FirebaseFirestore.instance.collection('Jobs');
  final CollectionReference _drivers =
      FirebaseFirestore.instance.collection('Drivers');
  final CollectionReference _mechanics =
      FirebaseFirestore.instance.collection('Mechanics');

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getStatus();
  }

  @override
  void dispose() {
    ratingController.dispose();
    super.dispose();
  }

  void getCurrentUser() {
    currentUser = auth.currentUser;
    userEmail = currentUser?.email;
  }

  Future<void> getStatus() async {
    if (userEmail == null) return;

    try {
      QuerySnapshot requestsQuery = await _jobs
          .where("driverEmail", isEqualTo: userEmail)
          .where("jobRequestStatus", whereIn: [
        "requested",
        "accepted",
        "completed",
        "completed/paid"
      ]).get();

      status = "";
      if (requestsQuery.docs.isNotEmpty) {
        mecEmail = requestsQuery.docs.first['mechanicEmail'];
        driverEmail = requestsQuery.docs.first['driverEmail'];
        fee = requestsQuery.docs.first['fee'];
      }

      for (var document in requestsQuery.docs) {
        switch (document['jobRequestStatus']) {
          case 'requested':
          case '':
            status = "requested";
            docId = document.id;
            break;
          case 'accepted':
            status = "accepted";
            docId = document.id;
            break;
          case 'completed':
            status = "completed";
            docId = document.id;
            break;
          case 'completed/paid':
            status = "completed/paid";
            docId = document.id;
            break;
          default:
            status = "";
        }
      }

      QuerySnapshot driverQuery =
          await _drivers.where("email", isEqualTo: userEmail).get();

      if (driverQuery.docs.isNotEmpty) {
        userName = driverQuery.docs.first['fname'];
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error getting status: $e');
    }
  }

  Future<void> setRating() async {
    try {
      QuerySnapshot ratingQuery = await _jobs
          .where("mechanicEmail", isEqualTo: mecEmail)
          .where("jobRequestStatus", isEqualTo: "completed/paid/rated")
          .get();

      var length = ratingQuery.docs.length;
      num ratingTotal = 0;
      for (var document in ratingQuery.docs) {
        ratingTotal += document['rating'];
      }

      var tempRating = (ratingTotal / length);

      QuerySnapshot mechanicQuery =
          await _mechanics.where("email", isEqualTo: mecEmail).get();

      if (mechanicQuery.docs.isNotEmpty) {
        var tempMecId = mechanicQuery.docs.first.id;
        await _mechanics.doc(tempMecId).update({"rating": tempRating});
      }
    } catch (e) {
      debugPrint('Error setting rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      bottomNavigationBar: BottomNavDriverWidget(),
      body: userName == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: size.width * 0.5),
                        child: Text(
                          'Hello... Welcome back $userName',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Gabriela-Regular",
                            color: Color.fromARGB(255, 3, 48, 85),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<QuerySnapshot>(
                      stream: _jobs
                          .where("driverEmail", isEqualTo: userEmail)
                          .where("jobRequestStatus", whereIn: [
                        "requested",
                        "accepted",
                        "completed",
                        "completed/paid"
                      ]).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (snapshot.hasData &&
                            snapshot.data!.docs.isNotEmpty) {
                          var jobStatus = snapshot.data!.docs.first
                              .get('jobRequestStatus') as String;
                          switch (jobStatus) {
                            case 'requested':
                              return jobRequestWidget(context);
                            case 'accepted':
                              return currentJobWidget(context);
                            case 'completed':
                              return paymentWidget(size, context);
                            case 'completed/paid':
                              return ratingWidget(size, context);
                            default:
                              return getAssistance(size, context);
                          }
                        }
                        return getAssistance(size, context);
                      },
                    ),
                    const SizedBox(height: 15),
                    previousJobsWidget(context),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        chatAdminWidget(context),
                        const SizedBox(width: 25),
                        profileWidget(context),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget chatAdminWidget(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () =>
          GoRouter.of(context).go('/driver/chatWithAdmin/$userName-admin'),
      child: Container(
        height: size.height * 0.15,
        width: size.width * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.7),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.0015),
            const Text(
              'Chat Admin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gabriela-Regular',
              ),
            ),
            SizedBox(height: size.height * 0.0015),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/chatAdmin.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget profileWidget(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/driver/driverProfile'),
      child: Container(
        height: size.height * 0.15,
        width: size.width * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.7),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.0015),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gabriela-Regular',
              ),
            ),
            SizedBox(height: size.height * 0.0015),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/profile1.png'),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget previousJobsWidget(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/driver/jobHistoryDriver'),
      child: Container(
        height: size.height * 0.2,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.7),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.01),
            const Text(
              'Job History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gabriela-Regular',
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/previousJobs.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget getAssistance(Size size, BuildContext context) {
    return Container(
      height: size.height * 0.33,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.7),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: size.height * 0.20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              image: const DecorationImage(
                  image: AssetImage('assets/images/getAssistance.jpg'),
                  fit: BoxFit.cover),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                const Flexible(
                  child: Text(
                    'mechanics in your area are ready to help you...',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    GoRouter.of(context).go('/driver/nearestMechanics');
                  },
                  style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      side: const BorderSide(width: 3, color: Colors.blue),
                      elevation: 15),
                  child: const Text('Get Assistance'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget jobRequestWidget(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.7),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListView(children: [
        Column(
          children: [
            SizedBox(height: size.height * 0.02),
            const Text(
              'Assistance requested. waiting for a response from the rescuer...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gabriela-Regular',
              ),
            ),
            Container(
              height: size.height * 0.2,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/images/jobRequest.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.01),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      GoRouter.of(context).go(
                          '/driver/chatWithMechanic/$driverEmail-$mecEmail');
                    },
                    splashColor: Colors.grey.withOpacity(0.5),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 3.5, color: Colors.blue),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.chat, size: 40, color: Colors.blue),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: const Text(
                              'Chat With rescuer',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.025),
                  InkWell(
                    onTap: () {
                      try {
                        _jobs.doc(docId).update({
                          "jobRequestStatus": "canceled",
                        });
                        getStatus();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Canceled Job Request.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    splashColor: Colors.grey.withOpacity(0.5),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 3.5, color: Colors.blue),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.close, size: 40, color: Colors.red),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: const Text(
                              'Cancel the Request',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget currentJobWidget(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.425,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.7),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: size.height * 0.002),
          const Text(
            'Your rescuer is on the way...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Gabriela-Regular',
            ),
          ),
          Container(
            height: size.height * 0.2,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                  image: AssetImage('assets/images/jobRequest.jpg'),
                  fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: size.height * 0.03),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.01),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    GoRouter.of(context)
                        .go('/driver/chatWithMechanic/$driverEmail-$mecEmail');
                  },
                  splashColor: Colors.grey.withOpacity(0.5),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 3.5, color: Colors.blue),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.chat, size: 40, color: Colors.blue),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: const Text(
                            'Chat With rescuer',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.025),
                InkWell(
                  onTap: () {
                    GoRouter.of(context).go('/driver/liveLocation');
                  },
                  splashColor: Colors.grey.withOpacity(0.5),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 3.5, color: Colors.blue),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.pin_drop,
                            size: 40, color: Colors.blue),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: const Text(
                            "Rescuer Location",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.025),
                InkWell(
                  onTap: () {
                    try {
                      _jobs.doc(docId).update({
                        "jobRequestStatus": "canceled",
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Canceled the job.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      setState(() {});
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                  splashColor: Colors.grey.withOpacity(0.5),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 3.5, color: Colors.blue),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.close, size: 40, color: Colors.red),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: const Text(
                            'Cancel the Job',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentWidget(Size size, BuildContext context) {
    return Container(
      height: size.height * 0.33,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.7),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: size.height * 0.20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              image: const DecorationImage(
                  image: AssetImage('assets/images/mechanic job is done.jpg'),
                  fit: BoxFit.cover),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                const Flexible(
                  child: Text(
                    'The mechanic has successfully completed the job.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _jobs
                            .doc(docId)
                            .update({"jobRequestStatus": "completed/paid"});
                      },
                      style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          side: const BorderSide(width: 3, color: Colors.green),
                          elevation: 15),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget ratingWidget(Size size, BuildContext context) {
    return Container(
      height: size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.7),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: size.height * 0.25,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              image: const DecorationImage(
                image: AssetImage('assets/images/rating.jpg'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    const Text(
                      'Rate your previous job',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    RatingBar.builder(
                      itemCount: 5,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          ratingVal = rating.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Text('Rating: $ratingVal'),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: ratingController,
                      minLines: 4,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Give your feedback...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _jobs.doc(docId).update({
                      "jobRequestStatus": "completed/paid/skippedRating",
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    side: const BorderSide(width: 3, color: Colors.blue),
                    elevation: 15,
                  ),
                  child: const Text('Skip'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _jobs.doc(docId).update({
                        "jobRequestStatus": "completed/paid/rated",
                        "rating": ratingVal,
                        "feedback": ratingController.text,
                      });
                      setRating();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully Rated'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    side: const BorderSide(width: 3, color: Colors.blue),
                    elevation: 15,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

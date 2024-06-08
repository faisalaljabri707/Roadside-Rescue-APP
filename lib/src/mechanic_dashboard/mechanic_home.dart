import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_nav_mechanic.dart';

class MechanicHome extends StatefulWidget {
  const MechanicHome({super.key});

  @override
  State<MechanicHome> createState() => _MechanicHomeState();
}

class _MechanicHomeState extends State<MechanicHome> {
  late TextEditingController feeController;
  late TextEditingController descriptionController;
  late TextEditingController vehicleNumController;
  String? status;
  String docId = "";
  String? mecEmail;
  String? driverEmail;
  String? userName;
  final CollectionReference _jobs =
      FirebaseFirestore.instance.collection('Jobs');
  final CollectionReference _mechanics =
      FirebaseFirestore.instance.collection('Mechanics');

  @override
  void initState() {
    super.initState();
    feeController = TextEditingController();
    descriptionController = TextEditingController();
    vehicleNumController = TextEditingController();
    getStatus();
  }

  @override
  void dispose() {
    feeController.dispose();
    descriptionController.dispose();
    vehicleNumController.dispose();
    super.dispose();
  }

  Future<void> getStatus() async {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) return;

    QuerySnapshot requestsQuery = await _jobs
        .where("mechanicEmail", isEqualTo: userEmail)
        .where("jobRequestStatus", whereIn: ["requested", "accepted"]).get();

    if (requestsQuery.docs.isNotEmpty) {
      setState(() {
        mecEmail = requestsQuery.docs.first['mechanicEmail'];
        driverEmail = requestsQuery.docs.first['driverEmail'];
        status = requestsQuery.docs.first['jobRequestStatus'];
        docId = requestsQuery.docs.first.id;
      });
    }

    QuerySnapshot mechanicQuery =
        await _mechanics.where("email", isEqualTo: userEmail).get();

    if (mechanicQuery.docs.isNotEmpty) {
      setState(() {
        userName = mechanicQuery.docs.first['fname'];
      });
    }
  }

  Future<void> updateJobStatus(String newStatus) async {
    if (docId.isNotEmpty) {
      await _jobs.doc(docId).update({"jobRequestStatus": newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job $newStatus.'),
          backgroundColor:
              newStatus == 'completed' ? Colors.green : Colors.blue,
        ),
      );
      getStatus();
    } else {
      print("docId is empty or null");
    }
  }

  Future<void> completeJob() async {
    if (docId.isNotEmpty) {
      await _jobs.doc(docId).update({
        "fee": feeController.text,
        "description": descriptionController.text,
        "vehicle": vehicleNumController.text,
        "jobRequestStatus": "completed",
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job Completed.'),
          backgroundColor: Colors.green,
        ),
      );
      getStatus();
    } else {
      print("docId is empty or null");
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      bottomNavigationBar: const BottomNavMechanicWidget(),
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
                            fontFamily: 'Gabriela-Regular',
                            color: Color.fromARGB(255, 3, 48, 85),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    StreamBuilder(
                      stream: _jobs
                          .where("mechanicEmail",
                              isEqualTo:
                                  FirebaseAuth.instance.currentUser?.email)
                          .where("jobRequestStatus", whereIn: [
                        "requested",
                        "accepted",
                        "completed"
                      ]).snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data!.docs.isNotEmpty) {
                            var jobData = snapshot.data!.docs[0].data()
                                as Map<String, dynamic>;
                            status = jobData['jobRequestStatus'];
                            return status == 'requested'
                                ? jobRequestWidget(context, jobData)
                                : status == 'accepted'
                                    ? currentJobWidget(context, jobData)
                                    : emptyJobWidget(context);
                          } else {
                            return emptyJobWidget(context);
                          }
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    previousJobsWidget(context),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        chatAdminWidget(context),
                        const SizedBox(width: 25),
                        profileWidget(context),
                      ],
                    ),
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
          GoRouter.of(context).go('/mechanic/chatWithAdmin/$userName-admin'),
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(0),
                    bottom: Radius.circular(20),
                  ),
                  image: DecorationImage(
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
      onTap: () => GoRouter.of(context).go('/mechanic/mechanicProfile'),
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(0),
                    bottom: Radius.circular(20),
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/images/profile1.png'),
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

  Widget previousJobsWidget(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/mechanic/jobHistoryMechanic'),
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
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(0),
                    bottom: Radius.circular(20),
                  ),
                  image: DecorationImage(
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

  Widget jobRequestWidget(BuildContext context, Map<String, dynamic> jobData) {
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.02),
            const Text(
              'New Job Request - 5KM away...',
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
                          '/mechanic/chatWithDriver/${jobData['driverEmail']}-${jobData['mechanicEmail']}');
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
                              'Chat With Driver',
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
                      updateJobStatus("accepted");
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
                          const Icon(Icons.done, size: 40, color: Colors.green),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: const Text(
                              'Accept the Job',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.green,
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
                      updateJobStatus("declined");
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
                              'Decline the Job',
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
      ),
    );
  }

  Widget currentJobWidget(BuildContext context, Map<String, dynamic> jobData) {
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
      child: ListView(
        children: [
          Column(
            children: [
              SizedBox(height: size.height * 0.02),
              const Text(
                'Current Job',
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
                        GoRouter.of(context).go(
                            '/mechanic/chatWithDriver/${jobData['driverEmail']}-${jobData['mechanicEmail']}');
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
                            const Icon(Icons.chat,
                                size: 40, color: Colors.blue),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 90),
                              child: const Text(
                                'Chat With Driver',
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
                        GoRouter.of(context).go('/mechanic/directions');
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
                            const Icon(Icons.navigation,
                                size: 40, color: Colors.blue),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 90),
                              child: const Text(
                                'Get Directions',
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
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Job Details'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: vehicleNumController,
                                    decoration: const InputDecoration(
                                        labelText: 'Vehicle Number'),
                                  ),
                                  TextField(
                                    controller: descriptionController,
                                    decoration: const InputDecoration(
                                        labelText: 'Description'),
                                  ),
                                  TextField(
                                    controller: feeController,
                                    decoration:
                                        const InputDecoration(labelText: 'Fee'),
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    completeJob();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Submit'),
                                ),
                              ],
                            );
                          },
                        );
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
                            const Icon(Icons.done,
                                size: 40, color: Colors.green),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 90),
                              child: const Text(
                                'Job Completed',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.green,
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
        ],
      ),
    );
  }

  Widget emptyJobWidget(BuildContext context) {
    var size = MediaQuery.of(context).size;
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
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
                bottom: Radius.circular(0),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.01),
                const Text(
                  'No jobs at the moment   :(',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gabriela-Regular',
                  ),
                ),
                SizedBox(height: size.height * 0.01),
              ],
            ),
          ),
          Container(
            height: size.height * 0.2,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(0),
                bottom: Radius.circular(20),
              ),
              image: DecorationImage(
                  image: AssetImage('assets/images/jobRequest.jpg'),
                  fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Check again in few minutes',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    getStatus();
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      side: const BorderSide(width: 3, color: Colors.blue),
                      elevation: 15),
                  child: const Text(
                    'Refresh',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

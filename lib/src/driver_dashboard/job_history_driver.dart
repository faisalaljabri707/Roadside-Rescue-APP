// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/bottom_nav_mechanic.dart';

class JobHistoryDriver extends StatefulWidget {
  const JobHistoryDriver({super.key});

  @override
  State<JobHistoryDriver> createState() => _JobHistoryDriverState();
}

class _JobHistoryDriverState extends State<JobHistoryDriver> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? userEmail;
  final CollectionReference jobs =
      FirebaseFirestore.instance.collection('Jobs');

  @override
  void initState() {
    super.initState();
    userEmail = auth.currentUser?.email;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Color(0xff24688e)),
        toolbarHeight: 55,
        leadingWidth: 135,
        title: Text('Job History'),
      ),
      bottomNavigationBar: BottomNavMechanicWidget(),
      body: StreamBuilder<QuerySnapshot>(
        stream: jobs.where('driverEmail', isEqualTo: userEmail).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.all(15),
                child: Container(
                  padding: EdgeInsets.all(20.0),
                  height: size.height * 0.3,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        jobDetailRow('mechanic Email:', data['mechanicEmail']),
                        Divider(color: Colors.grey, height: 1),
                        jobDetailRow('Vehicle Number', data['vehicle']),
                        Divider(color: Colors.grey, height: 1),
                        jobDetailRow('Description:', data['description']),
                        Divider(color: Colors.grey, height: 1),
                        jobDetailRow('Date:', data['date']),
                        Divider(color: Colors.grey, height: 1),
                        jobDetailRow('Time:', data['time']),
                        Divider(color: Colors.grey, height: 1),
                        jobDetailRow('Rating:', data['rating']),
                        Divider(color: Colors.grey, height: 1),
                        jobDetailRow('Feedback:', data['feedback']),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget jobDetailRow(String title, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

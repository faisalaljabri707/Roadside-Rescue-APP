// ignore_for_file: camel_case_types, must_be_immutable, library_private_types_in_public_api, no_logic_in_create_state, prefer_final_fields, prefer_const_constructors, avoid_print, sized_box_for_whitespace, prefer_interpolation_to_compose_strings

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Messages extends StatefulWidget {
  final String id;
  Messages({super.key, required this.id});

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final CollectionReference _messages =
      FirebaseFirestore.instance.collection('Messages');
  final CollectionReference _drivers =
      FirebaseFirestore.instance.collection('Drivers');
  final CollectionReference _mechanics =
      FirebaseFirestore.instance.collection('Mechanics');

  String? userEmail;
  String name = "Kevin";

  @override
  void initState() {
    super.initState();
    getUserEmail();
    getName();
  }

  void getUserEmail() {
    userEmail = auth.currentUser?.email;
  }

  Future<void> getName() async {
    if (userEmail == null) return;

    try {
      QuerySnapshot messageQuery = await _messages
          .where("id", isEqualTo: widget.id)
          .where("email", isNotEqualTo: userEmail)
          .get();

      if (messageQuery.docs.isNotEmpty) {
        String tempEmail = messageQuery.docs.first['email'];

        QuerySnapshot driverQuery =
            await _drivers.where("email", isEqualTo: tempEmail).get();
        if (driverQuery.docs.isNotEmpty) {
          name = driverQuery.docs.first['fname'];
        } else {
          QuerySnapshot mechanicQuery =
              await _mechanics.where("email", isEqualTo: tempEmail).get();
          if (mechanicQuery.docs.isNotEmpty) {
            name = mechanicQuery.docs.first['fname'];
          }
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error getting name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _messages
          .where("id", isEqualTo: widget.id)
          .orderBy('time')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Something went wrong: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No messages"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          physics: ScrollPhysics(),
          shrinkWrap: true,
          primary: true,
          itemBuilder: (context, index) {
            QueryDocumentSnapshot qs = snapshot.data!.docs[index];
            Timestamp timestamp = qs['time'];
            DateTime dateTime = timestamp.toDate();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: userEmail == qs['email']
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 300,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.purple),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      title: Text(
                        qs['email'] == userEmail ? "You" : name,
                        style: TextStyle(fontSize: 15),
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 200,
                            child: Text(
                              qs['message'],
                              softWrap: true,
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          Text(
                            "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}",
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

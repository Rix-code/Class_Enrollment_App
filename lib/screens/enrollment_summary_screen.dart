import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class EnrollmentSummaryScreen extends StatefulWidget {
  @override
  _EnrollmentSummaryScreenState createState() =>
      _EnrollmentSummaryScreenState();
}

class _EnrollmentSummaryScreenState extends State<EnrollmentSummaryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int totalCredits = 0;
  String studentId = "";

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      studentId = user.uid;
      _loadStudentCredits();
    }
  }

  Future<void> _loadStudentCredits() async {
    try {
      final studentDoc =
      await _firestore.collection('students').doc(studentId).get();
      if (studentDoc.exists) {
        final data = studentDoc.data() as Map<String, dynamic>;
        setState(() {
          totalCredits = data['credits'] ?? 0;
        });
      }
    } catch (e) {
      print("Error loading credits: $e");
    }
  }

  Future<void> _dropSubject(
      BuildContext context, String enrollmentId, String subjectId, int subjectCredits) async {
    try {
      // Delete enrollment
      await _firestore.collection('enrollments').doc(enrollmentId).delete();

      // Decrease enrolled count in the subject
      await _firestore.collection('subjects').doc(subjectId).update({
        'enrolled': FieldValue.increment(-1),
      });

      // Update student credits locally and in Firestore
      await _firestore.collection('students').doc(studentId).update({
        'credits': FieldValue.increment(-subjectCredits),
      });

      setState(() {
        totalCredits -= subjectCredits;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subject dropped successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error dropping subject: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (studentId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Enrollment Summary')),
        body: Center(child: Text('User is not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Enrollment Summary'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Credits Section
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Credits:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalCredits/24',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Enrolled Subjects List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('enrollments')
                  .where('studentId', isEqualTo: studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No subjects enrolled yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final enrollments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = enrollments[index];
                    final subjectId = enrollment['subjectId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('subjects').doc(subjectId).get(),
                      builder: (context, subjectSnapshot) {
                        if (!subjectSnapshot.hasData) {
                          return SizedBox.shrink();
                        }

                        final subjectData = subjectSnapshot.data!.data()
                        as Map<String, dynamic>?;
                        if (subjectData == null) {
                          return SizedBox.shrink();
                        }

                        final subjectCode = subjectData['code'] ?? 'Unknown';
                        final subjectName = subjectData['name'] ?? 'Unknown';
                        final subjectCredits = subjectData['credits'] ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                '$subjectCredits',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              '$subjectCode - $subjectName',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Credits: $subjectCredits',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _dropSubject(
                                context,
                                enrollment.id,
                                subjectId,
                                subjectCredits,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
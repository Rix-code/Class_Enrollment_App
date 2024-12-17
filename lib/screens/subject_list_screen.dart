import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/enrollment_service.dart';

class SubjectListScreen extends StatefulWidget {
  @override
  _SubjectListScreenState createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Subjects'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No subjects available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final subjects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final data = subject.data() as Map<String, dynamic>;

              // Safely parse numeric fields
              final capacity = _parseToInt(data['capacity'], 0);
              final enrolled = _parseToInt(data['enrolled'], 0);
              final subjectCredits = _parseToInt(data['credits'], 0);
              final available = capacity - enrolled;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['code']} - ${data['name']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Credits: $subjectCredits',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Available: $available/$capacity',
                        style: TextStyle(
                          fontSize: 16,
                          color: available > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: available > 0
                              ? () => _enrollSubject(subject.id, subjectCredits)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            available > 0 ? Colors.green : Colors.grey,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                          child: Text(
                            'Enroll',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _enrollSubject(String subjectId, int subjectCredits) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User is not authenticated')),
        );
        return;
      }

      final studentId = user.uid;
      final studentRef = _firestore.collection('students').doc(studentId);

      // Ensure student document exists
      final studentDoc = await studentRef.get();
      if (!studentDoc.exists) {
        // Create a new student document if it doesn't exist
        await studentRef.set({
          'name': user.displayName ?? 'Unknown', // Default name
          'credits': 0, // Initialize credits to 0
        });
      }

      final studentData = (await studentRef.get()).data()!;
      final currentCredits = _parseToInt(studentData['credits'], 0);

      final subjectRef = _firestore.collection('subjects').doc(subjectId);
      final subjectDoc = await subjectRef.get();

      if (!subjectDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subject not found')),
        );
        return;
      }

      final subjectData = subjectDoc.data()!;
      final capacity = _parseToInt(subjectData['capacity'], 0);
      final enrolled = _parseToInt(subjectData['enrolled'], 0);

      final enrollmentsQuery = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('subjectId', isEqualTo: subjectId)
          .get();

      if (enrollmentsQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already enrolled in this subject!')),
        );
        return;
      }

      if (enrolled >= capacity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No more spots available for this subject!')),
        );
        return;
      }

      const maxCredits = 24;
      if (currentCredits + subjectCredits > maxCredits) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Enrolling exceeds your maximum allowed credits!')),
        );
        return;
      }

      await _firestore.collection('enrollments').add({
        'studentId': studentId,
        'subjectId': subjectId,
        'enrollmentDate': FieldValue.serverTimestamp(),
      });

      await subjectRef.update({
        'enrolled': enrolled + 1,
      });

      await studentRef.update({
        'credits': currentCredits + subjectCredits,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully enrolled in the subject!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enrollment failed: ${e.toString()}')),
      );
    }
  }

  int _parseToInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }
}
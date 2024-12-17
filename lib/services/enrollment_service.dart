import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int maxCredits = 24;

  Future<int> getCurrentCredits(String studentId) async {
    int totalCredits = 0;

    final enrollments = await _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .get();

    for (var enrollment in enrollments.docs) {
      final subject = await _firestore
          .collection('subjects')
          .doc(enrollment.get('subjectId'))
          .get();
      totalCredits += subject.get('credits') as int;
    }

    return totalCredits;
  }

  Future<bool> isAlreadyEnrolled(String studentId, String subjectId) async {
    final existingEnrollment = await _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .get();

    return existingEnrollment.docs.isNotEmpty;
  }

  Future<bool> enrollSubject(String studentId, String subjectId) async {
    try {
      final alreadyEnrolled = await isAlreadyEnrolled(studentId, subjectId);
      if (alreadyEnrolled) {
        throw Exception('You are already enrolled in this subject');
      }

      final subject = await _firestore.collection('subjects').doc(subjectId).get();
      final currentCredits = await getCurrentCredits(studentId);
      final subjectCredits = subject.get('credits') as int;

      if (currentCredits + subjectCredits > maxCredits) {
        throw Exception('Exceeds maximum credits limit of $maxCredits');
      }

      if (subject.get('enrolled') >= subject.get('capacity')) {
        throw Exception('Subject is full');
      }

      await _firestore.collection('enrollments').add({
        'studentId': studentId,
        'subjectId': subjectId,
        'enrollmentDate': DateTime.now(),
      });

      await _firestore.collection('subjects').doc(subjectId).update({
        'enrolled': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      throw e;
    }
  }
}

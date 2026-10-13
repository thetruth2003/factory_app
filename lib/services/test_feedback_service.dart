import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workflow.dart';

class TestFeedbackService {
  TestFeedbackService(this.db);
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> records(String companyId) =>
      db.collection('companies').doc(companyId).collection('test_feedback');

  Future<void> submit({
    required String id,
    required FactoryUser actor,
    required int ease,
    required String notes,
    required String locale,
  }) async {
    Workflow.validateActor(actor);
    if (!actor.isTraining) throw const WorkflowException('forbidden');
    if (notes.trim().isEmpty) throw const WorkflowException('noteRequired');
    if (ease < 1 || ease > 5 || notes.trim().length > 2000) {
      throw const WorkflowException('invalidFeedback');
    }
    final ref = records(actor.companyId).doc(id);
    // One form ID survives retries, including a lost successful response.
    await db.runTransaction((tx) async {
      final existing = (await tx.get(ref)).data();
      if (existing != null) {
        if (existing['createdByUid'] != actor.uid ||
            existing['companyId'] != actor.companyId) {
          throw const WorkflowException('forbidden');
        }
        return;
      }
      tx.set(ref, {
        'schemaVersion': 1,
        'environment': 'training',
        'companyId': actor.companyId,
        'createdByUid': actor.uid,
        'createdByName': actor.name,
        'createdByRole': actor.role,
        'createdAt': FieldValue.serverTimestamp(),
        'ease': ease,
        'notes': notes.trim(),
        'locale': locale,
        'appVersion': '1.2.3+6',
      });
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedMachines12() async {
    final machineIds = <String>[
      '1A',
      '1B',
      '1C',
      '2A',
      '2B',
      '2C',
      '3A',
      '3B',
      '3C',
      '4A',
      '4B',
      '4C',
    ];

    final batch = _db.batch();

    for (final id in machineIds) {
      final section = id.substring(0, 1);
      final ref = _db.collection('machines').doc(id);

      batch.set(ref, {
        'section': section,
        'name': id,
        'activeCategory': 'green',
        'activeStatus': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}

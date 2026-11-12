import 'package:cloud_firestore/cloud_firestore.dart';

class GiangVienService {
  final CollectionReference<Map<String, dynamic>> giangVien =
      FirebaseFirestore.instance.collection('GiangVien');

  Future<void> addGiangVien({
    required String idgv,
    required String fullname,
    required String image,
    required int sumClass,
  }) async {
    await giangVien.add({
      'IDGV': idgv,
      'Fullname': fullname,
      'Image': image,
      'SumClass': sumClass,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getGiangVien() {
    return giangVien.snapshots();
  }

  Future<bool> idExists(
    String idgv, {
    String? excludeDocumentId,
  }) async {
    final snapshot = await giangVien.get();
    final target = idgv.trim().toLowerCase();

    return snapshot.docs.any((doc) {
      if (doc.id == excludeDocumentId) return false;
      final current =
          doc.data()['IDGV']?.toString().trim().toLowerCase() ?? '';
      return current == target;
    });
  }

  Future<void> updateGiangVien({
    required String documentId,
    required String idgv,
    required String fullname,
    required String image,
    required int sumClass,
  }) async {
    await giangVien.doc(documentId).update({
      'IDGV': idgv,
      'Fullname': fullname,
      'Image': image,
      'SumClass': sumClass,
    });
  }

  Future<void> deleteGiangVien(String documentId) async {
    await giangVien.doc(documentId).delete();
  }
}

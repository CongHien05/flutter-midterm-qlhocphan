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

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/giang_vien_service.dart';
import '../widgets/giang_vien_form.dart';

class GiangVienScreen extends StatelessWidget {
  const GiangVienScreen({super.key});

  Uint8List? decodeImage(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;

    try {
      return base64Decode(value.toString());
    } catch (_) {
      return null;
    }
  }

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> addGiangVien(
    BuildContext context,
    GiangVienService service,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const GiangVienForm(),
    );

    if (result == null) return;

    try {
      await service.addGiangVien(
        idgv: result['IDGV'],
        fullname: result['Fullname'],
        image: result['Image'],
        sumClass: result['SumClass'],
      );

      if (context.mounted) {
        showMessage(context, 'Thêm giảng viên thành công');
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Không thể thêm giảng viên');
      }
    }
  }

  Future<void> editGiangVien(
    BuildContext context,
    GiangVienService service,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => GiangVienForm(
        idgv: data['IDGV']?.toString() ?? '',
        fullname: data['Fullname']?.toString() ?? '',
        image: data['Image']?.toString() ?? '',
        sumClass: (data['SumClass'] as num?)?.toInt() ?? 0,
      ),
    );

    if (result == null) return;

    try {
      await service.updateGiangVien(
        documentId: documentId,
        idgv: result['IDGV'],
        fullname: result['Fullname'],
        image: result['Image'],
        sumClass: result['SumClass'],
      );

      if (context.mounted) {
        showMessage(context, 'Cập nhật thành công');
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Không thể cập nhật');
      }
    }
  }

  Future<void> deleteGiangVien(
    BuildContext context,
    GiangVienService service,
    String documentId,
    String fullname,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa giảng viên'),
        content: Text('Bạn có chắc muốn xóa "$fullname"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await service.deleteGiangVien(documentId);

      if (context.mounted) {
        showMessage(context, 'Đã xóa giảng viên');
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Không thể xóa giảng viên');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = GiangVienService();
    final authService = AuthService();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý giảng viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: authService.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.getGiangVien(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Không thể tải dữ liệu'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Chưa có giảng viên. Nhấn + để thêm.'),
            );
          }

          final docs = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth =
                  constraints.maxWidth > 900 ? 900.0 : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final document = docs[index];
                      final data = document.data();

                      final idgv = data['IDGV']?.toString() ?? '';
                      final fullname = data['Fullname']?.toString() ?? '';
                      final sumClass =
                          (data['SumClass'] as num?)?.toInt() ?? 0;
                      final imageBytes = decodeImage(data['Image']);

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: colors.primaryContainer,
                            backgroundImage: imageBytes != null
                                ? MemoryImage(imageBytes)
                                : null,
                            child: imageBytes == null
                                ? Icon(
                                    Icons.person_rounded,
                                    color: colors.primary,
                                  )
                                : null,
                          ),
                          title: Text(
                            fullname,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'IDGV: $idgv\nSố lớp: $sumClass',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Sửa',
                                onPressed: () => editGiangVien(
                                  context,
                                  service,
                                  document.id,
                                  data,
                                ),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Xóa',
                                onPressed: () => deleteGiangVien(
                                  context,
                                  service,
                                  document.id,
                                  fullname,
                                ),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addGiangVien(context, service),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Thêm'),
      ),
    );
  }
}

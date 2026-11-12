import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/giang_vien_service.dart';
import '../widgets/giang_vien_detail.dart';
import '../widgets/giang_vien_form.dart';

class GiangVienScreen extends StatefulWidget {
  const GiangVienScreen({super.key});

  @override
  State<GiangVienScreen> createState() => _GiangVienScreenState();
}

class _GiangVienScreenState extends State<GiangVienScreen> {
  final service = GiangVienService();
  final authService = AuthService();
  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  String keyword = '';

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  Uint8List? decodeImage(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      return base64Decode(value.toString());
    } catch (_) {
      return null;
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> addGiangVien() async {
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
      if (mounted) showMessage('Thêm giảng viên thành công');
    } catch (_) {
      if (mounted) showMessage('Không thể thêm giảng viên');
    }
  }

  Future<void> editGiangVien(
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
      if (mounted) showMessage('Cập nhật thành công');
    } catch (_) {
      if (mounted) showMessage('Không thể cập nhật');
    }
  }

  Future<void> deleteGiangVien(String documentId, String fullname) async {
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
      if (mounted) showMessage('Đã xóa giảng viên');
    } catch (_) {
      if (mounted) showMessage('Không thể xóa giảng viên');
    }
  }

  Future<void> showDetail(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final action = await showDialog<String>(
      context: context,
      builder: (_) => GiangVienDetail(data: data),
    );

    if (!mounted) return;
    if (action == 'edit') {
      await editGiangVien(documentId, data);
    } else if (action == 'delete') {
      await deleteGiangVien(
        documentId,
        data['Fullname']?.toString() ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded),
            SizedBox(width: 10),
            Text(
              'QL Học phần',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: authService.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
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

          final docs = snapshot.data?.docs ?? [];
          final filtered = docs.where((doc) {
            final data = doc.data();
            final text =
                '${data['IDGV'] ?? ''} ${data['Fullname'] ?? ''}'.toLowerCase();
            return text.contains(keyword.toLowerCase());
          }).toList();

          final totalClasses = docs.fold<int>(
            0,
            (sum, doc) =>
                sum + ((doc.data()['SumClass'] as num?)?.toInt() ?? 0),
          );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng quan giảng viên',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Theo dõi thông tin giảng viên và số lớp đang phụ trách.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.groups_2_outlined,
                            label: 'Giảng viên',
                            value: docs.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.class_outlined,
                            label: 'Tổng số lớp',
                            value: totalClasses.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            focusNode: searchFocus,
                            onChanged: (value) {
                              setState(() => keyword = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Tìm theo mã hoặc tên giảng viên',
                              prefixIcon:
                                  const Icon(Icons.search_rounded),
                              suffixIcon: keyword.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Xóa tìm kiếm',
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() => keyword = '');
                                        searchFocus.requestFocus();
                                      },
                                      icon:
                                          const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: addGiangVien,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Thêm giảng viên'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE8EBF2),
                          ),
                        ),
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  docs.isEmpty
                                      ? 'Chưa có giảng viên.'
                                      : 'Không tìm thấy giảng viên phù hợp.',
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(10),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final document = filtered[index];
                                  final data = document.data();
                                  final imageBytes =
                                      decodeImage(data['Image']);

                                  return ListTile(
                                    onTap: () =>
                                        showDetail(document.id, data),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 28,
                                      backgroundColor:
                                          colors.primaryContainer,
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
                                      data['Fullname']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'IDGV: ${data['IDGV'] ?? ''}   •   '
                                        '${data['SumClass'] ?? 0} lớp',
                                      ),
                                    ),
                                    trailing: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: colors.primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        color: colors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.primaryContainer,
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

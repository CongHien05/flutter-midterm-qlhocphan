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
  late final Stream<QuerySnapshot<Map<String, dynamic>>> giangVienStream;
  String keyword = '';
  String classFilter = 'all';
  String sortBy = 'name';

  @override
  void initState() {
    super.initState();
    giangVienStream = service.getGiangVien();
  }

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
      if (await service.idExists(result['IDGV'])) {
        if (mounted) showMessage('Mã giảng viên đã tồn tại');
        return;
      }

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
      if (await service.idExists(
        result['IDGV'],
        excludeDocumentId: documentId,
      )) {
        if (mounted) showMessage('Mã giảng viên đã tồn tại');
        return;
      }

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
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              onPressed: authService.logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: giangVienStream,
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
            final classes = (data['SumClass'] as num?)?.toInt() ?? 0;

            final matchesSearch = text.contains(keyword.toLowerCase());
            final matchesFilter = switch (classFilter) {
              'zero' => classes == 0,
              '1to3' => classes >= 1 && classes <= 3,
              '4plus' => classes >= 4,
              _ => true,
            };

            return matchesSearch && matchesFilter;
          }).toList();

          filtered.sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aClasses = (aData['SumClass'] as num?)?.toInt() ?? 0;
            final bClasses = (bData['SumClass'] as num?)?.toInt() ?? 0;

            return switch (sortBy) {
              'classAsc' => aClasses.compareTo(bClasses),
              'classDesc' => bClasses.compareTo(aClasses),
              _ => (aData['Fullname']?.toString() ?? '')
                  .toLowerCase()
                  .compareTo(
                    (bData['Fullname']?.toString() ?? '').toLowerCase(),
                  ),
            };
          });

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
                    LayoutBuilder(
                      builder: (context, box) {
                        final compact = box.maxWidth < 600;

                        final search = TextField(
                          controller: searchController,
                          focusNode: searchFocus,
                          onChanged: (value) {
                            setState(() => keyword = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm theo mã hoặc tên giảng viên',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: keyword.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Xóa tìm kiếm',
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() => keyword = '');
                                      searchFocus.requestFocus();
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        );

                        final addButton = FilledButton.icon(
                          onPressed: addGiangVien,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Thêm giảng viên'),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              search,
                              const SizedBox(height: 10),
                              addButton,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: search),
                            const SizedBox(width: 12),
                            addButton,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'Tất cả',
                                  selected: classFilter == 'all',
                                  onSelected: () =>
                                      setState(() => classFilter = 'all'),
                                ),
                                _FilterChip(
                                  label: '0 lớp',
                                  selected: classFilter == 'zero',
                                  onSelected: () =>
                                      setState(() => classFilter = 'zero'),
                                ),
                                _FilterChip(
                                  label: '1–3 lớp',
                                  selected: classFilter == '1to3',
                                  onSelected: () =>
                                      setState(() => classFilter = '1to3'),
                                ),
                                _FilterChip(
                                  label: '≥ 4 lớp',
                                  selected: classFilter == '4plus',
                                  onSelected: () =>
                                      setState(() => classFilter = '4plus'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          tooltip: 'Sắp xếp',
                          initialValue: sortBy,
                          onSelected: (value) =>
                              setState(() => sortBy = value),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'name',
                              child: Text('Tên A–Z'),
                            ),
                            PopupMenuItem(
                              value: 'classDesc',
                              child: Text('Số lớp: cao → thấp'),
                            ),
                            PopupMenuItem(
                              value: 'classAsc',
                              child: Text('Số lớp: thấp → cao'),
                            ),
                          ],
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.sort_rounded),
                            label: const Text('Sắp xếp'),
                          ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
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

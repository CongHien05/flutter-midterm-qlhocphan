import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/giang_vien_service.dart';
import '../utils/json_exporter.dart';
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
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa giảng viên "$fullname"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
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

  void exportDatabase(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final data = docs.map((doc) {
      final item = doc.data();
      return {
        'IDGV': item['IDGV']?.toString() ?? '',
        'Fullname': item['Fullname']?.toString() ?? '',
        'Image': item['Image']?.toString() ?? '',
        'SumClass': (item['SumClass'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    final json = const JsonEncoder.withIndent('  ').convert({
      'GiangVien': data,
    });

    try {
      exportJsonFile(json);
      showMessage('Đã xuất file GiangVien.json');
    } catch (_) {
      showMessage('Xuất JSON chỉ hỗ trợ trên Web');
    }
  }

  Future<void> confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authService.logout();
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
        titleSpacing: 20,
        title: const Text(
          'Quản lý giảng viên',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 600)
            TextButton.icon(
              onPressed: confirmLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
            )
          else
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: confirmLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
          const SizedBox(width: 12),
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

          Map<String, dynamic>? topLecturer;
          for (final doc in docs) {
            final data = doc.data();
            final classes = (data['SumClass'] as num?)?.toInt() ?? 0;
            final top = (topLecturer?['SumClass'] as num?)?.toInt() ?? -1;
            if (classes > top) topLecturer = data;
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng quan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StatsRow(
                      lecturerCount: docs.length,
                      totalClasses: totalClasses,
                      topLecturer:
                          topLecturer?['Fullname']?.toString() ?? '-',
                    ),
                    const SizedBox(height: 16),
                    _Toolbar(
                      searchController: searchController,
                      searchFocus: searchFocus,
                      keyword: keyword,
                      onSearchChanged: (value) =>
                          setState(() => keyword = value),
                      onClear: () {
                        searchController.clear();
                        setState(() => keyword = '');
                        searchFocus.requestFocus();
                      },
                      onExport: () => exportDatabase(docs),
                      onAdd: addGiangVien,
                    ),
                    const SizedBox(height: 10),
                    _FilterRow(
                      selectedFilter: classFilter,
                      sortBy: sortBy,
                      onFilterChanged: (value) =>
                          setState(() => classFilter = value),
                      onSortChanged: (value) =>
                          setState(() => sortBy = value),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _LecturerList(
                        docs: filtered,
                        decodeImage: decodeImage,
                        onOpen: showDetail,
                      ),
                    ),
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

class _StatsRow extends StatelessWidget {
  final int lecturerCount;
  final int totalClasses;
  final String topLecturer;

  const _StatsRow({
    required this.lecturerCount,
    required this.totalClasses,
    required this.topLecturer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 700;

        final items = [
          _StatBox(
            label: 'Giảng viên',
            value: lecturerCount.toString(),
            icon: Icons.people_outline,
          ),
          _StatBox(
            label: 'Tổng số lớp',
            value: totalClasses.toString(),
            icon: Icons.class_outlined,
          ),
          _StatBox(
            label: 'Nhiều lớp nhất',
            value: topLecturer,
            icon: Icons.star_border_rounded,
            small: true,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                SizedBox(width: double.infinity, child: items[i]),
                if (i < items.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(child: items[i]),
              if (i < items.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool small;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: small ? 16 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final String keyword;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final VoidCallback onExport;
  final VoidCallback onAdd;

  const _Toolbar({
    required this.searchController,
    required this.searchFocus,
    required this.keyword,
    required this.onSearchChanged,
    required this.onClear,
    required this.onExport,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 650;

        final search = TextField(
          controller: searchController,
          focusNode: searchFocus,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Tìm mã hoặc tên giảng viên',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: keyword.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        );

        final export = OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Xuất JSON'),
        );

        final add = FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Thêm'),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  if (kIsWeb) ...[
                    Expanded(child: export),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: add),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            if (kIsWeb) ...[
              const SizedBox(width: 8),
              export,
            ],
            const SizedBox(width: 8),
            add,
          ],
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selectedFilter;
  final String sortBy;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;

  const _FilterRow({
    required this.selectedFilter,
    required this.sortBy,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FilterChip(
                label: 'Tất cả',
                value: 'all',
                selected: selectedFilter,
                onChanged: onFilterChanged,
              ),
              _FilterChip(
                label: '0 lớp',
                value: 'zero',
                selected: selectedFilter,
                onChanged: onFilterChanged,
              ),
              _FilterChip(
                label: '1–3 lớp',
                value: '1to3',
                selected: selectedFilter,
                onChanged: onFilterChanged,
              ),
              _FilterChip(
                label: '≥ 4 lớp',
                value: '4plus',
                selected: selectedFilter,
                onChanged: onFilterChanged,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Sắp xếp',
          initialValue: sortBy,
          onSelected: onSortChanged,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'name', child: Text('Tên A–Z')),
            PopupMenuItem(
              value: 'classDesc',
              child: Text('Số lớp cao → thấp'),
            ),
            PopupMenuItem(
              value: 'classAsc',
              child: Text('Số lớp thấp → cao'),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 18),
                SizedBox(width: 5),
                Text('Sắp xếp'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected == value,
      showCheckmark: false,
      onSelected: (_) => onChanged(value),
    );
  }
}

class _LecturerList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Uint8List? Function(dynamic) decodeImage;
  final Future<void> Function(String, Map<String, dynamic>) onOpen;

  const _LecturerList({
    required this.docs,
    required this.decodeImage,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            color: const Color(0xFFF8F9FA),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Giảng viên',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Mã GV',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'Số lớp',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 32),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: docs.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final document = docs[index];
                      final data = document.data();
                      final imageBytes = decodeImage(data['Image']);

                      return InkWell(
                        onTap: () => onOpen(document.id, data),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 21,
                                      backgroundImage: imageBytes != null
                                          ? MemoryImage(imageBytes)
                                          : null,
                                      child: imageBytes == null
                                          ? const Icon(Icons.person_outline)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        data['Fullname']?.toString() ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  data['IDGV']?.toString() ?? '',
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  data['SumClass']?.toString() ?? '0',
                                ),
                              ),
                              const SizedBox(
                                width: 32,
                                child: Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

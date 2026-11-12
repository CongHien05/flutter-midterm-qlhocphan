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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: giangVienStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Không thể tải dữ liệu')),
          );
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

        final topName = topLecturer?['Fullname']?.toString() ?? '-';

        return LayoutBuilder(
          builder: (context, box) {
            final desktop = box.maxWidth >= 900;

            return Scaffold(
              appBar: desktop
                  ? null
                  : AppBar(
                      title: const Text(
                        'Quản lý giảng viên',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      actions: [
                        IconButton(
                          tooltip: 'Đăng xuất',
                          onPressed: confirmLogout,
                          icon: const Icon(Icons.logout_rounded),
                        ),
                      ],
                    ),
              floatingActionButton: desktop
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: addGiangVien,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm'),
                    ),
              body: Row(
                children: [
                  if (desktop)
                    _Sidebar(
                      onAdd: addGiangVien,
                      onExport: () => exportDatabase(docs),
                      onLogout: confirmLogout,
                    ),
                  Expanded(
                    child: _Workspace(
                      desktop: desktop,
                      docs: filtered,
                      totalLecturers: docs.length,
                      totalClasses: totalClasses,
                      topLecturer: topName,
                      searchController: searchController,
                      searchFocus: searchFocus,
                      keyword: keyword,
                      classFilter: classFilter,
                      sortBy: sortBy,
                      decodeImage: decodeImage,
                      onSearchChanged: (value) =>
                          setState(() => keyword = value),
                      onClear: () {
                        searchController.clear();
                        setState(() => keyword = '');
                        searchFocus.requestFocus();
                      },
                      onFilterChanged: (value) =>
                          setState(() => classFilter = value),
                      onSortChanged: (value) =>
                          setState(() => sortBy = value),
                      onAdd: addGiangVien,
                      onExport: () => exportDatabase(docs),
                      onOpen: showDetail,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onExport;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.onAdd,
    required this.onExport,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 224,
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'QLHocPhan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'QUẢN LÝ',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white,
                  ),
                  title: Text(
                    'Giảng viên',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'THAO TÁC NHANH',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _SideAction(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Thêm giảng viên',
                onTap: onAdd,
              ),
              if (kIsWeb)
                _SideAction(
                  icon: Icons.download_outlined,
                  label: 'Xuất dữ liệu',
                  onTap: onExport,
                ),
              const Spacer(),
              const Divider(color: Color(0xFF334155)),
              _SideAction(
                icon: Icons.logout_rounded,
                label: 'Đăng xuất',
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SideAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      leading: Icon(icon, color: const Color(0xFFCBD5E1), size: 20),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _Workspace extends StatelessWidget {
  final bool desktop;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final int totalLecturers;
  final int totalClasses;
  final String topLecturer;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final String keyword;
  final String classFilter;
  final String sortBy;
  final Uint8List? Function(dynamic) decodeImage;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onAdd;
  final VoidCallback onExport;
  final Future<void> Function(String, Map<String, dynamic>) onOpen;

  const _Workspace({
    required this.desktop,
    required this.docs,
    required this.totalLecturers,
    required this.totalClasses,
    required this.topLecturer,
    required this.searchController,
    required this.searchFocus,
    required this.keyword,
    required this.classFilter,
    required this.sortBy,
    required this.decodeImage,
    required this.onSearchChanged,
    required this.onClear,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onAdd,
    required this.onExport,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: EdgeInsets.all(desktop ? 28 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (desktop) ...[
                _PageHeader(
                  desktop: desktop,
                  onAdd: onAdd,
                  onExport: onExport,
                ),
                const SizedBox(height: 18),
              ],
              _SummaryBar(
                totalLecturers: totalLecturers,
                totalClasses: totalClasses,
                topLecturer: topLecturer,
              ),
              SizedBox(height: desktop ? 18 : 10),
              _SearchAndFilter(
                searchController: searchController,
                searchFocus: searchFocus,
                keyword: keyword,
                classFilter: classFilter,
                sortBy: sortBy,
                onSearchChanged: onSearchChanged,
                onClear: onClear,
                onFilterChanged: onFilterChanged,
                onSortChanged: onSortChanged,
              ),
              SizedBox(height: desktop ? 12 : 8),
              Expanded(
                child: _LecturerTable(
                  docs: docs,
                  decodeImage: decodeImage,
                  onOpen: onOpen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool desktop;
  final VoidCallback onAdd;
  final VoidCallback onExport;

  const _PageHeader({
    required this.desktop,
    required this.onAdd,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giảng viên',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Quản lý danh sách và số lớp phụ trách.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        if (!desktop && kIsWeb)
          IconButton(
            tooltip: 'Xuất JSON',
            onPressed: onExport,
            icon: const Icon(Icons.download_outlined),
          ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 19),
          label: const Text('Thêm giảng viên'),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int totalLecturers;
  final int totalClasses;
  final String topLecturer;

  const _SummaryBar({
    required this.totalLecturers,
    required this.totalClasses,
    required this.topLecturer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 680;

          if (compact) {
            return SizedBox(
              height: 70,
              child: Row(
                children: [
                  Expanded(
                    child: _CompactSummaryItem(
                      label: 'Giảng viên',
                      value: '$totalLecturers',
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _CompactSummaryItem(
                      label: 'Số lớp',
                      value: '$totalClasses',
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _CompactSummaryItem(
                      label: 'Nhiều nhất',
                      value: topLecturer,
                      small: true,
                    ),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Tổng giảng viên',
                  value: '$totalLecturers',
                ),
              ),
              const SizedBox(height: 62, child: VerticalDivider(width: 1)),
              Expanded(
                child: _SummaryItem(
                  label: 'Tổng số lớp',
                  value: '$totalClasses',
                ),
              ),
              const SizedBox(height: 62, child: VerticalDivider(width: 1)),
              Expanded(
                flex: 2,
                child: _SummaryItem(
                  label: 'Phụ trách nhiều lớp nhất',
                  value: topLecturer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompactSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool small;

  const _CompactSummaryItem({
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: small ? 13 : 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final String keyword;
  final String classFilter;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;

  const _SearchAndFilter({
    required this.searchController,
    required this.searchFocus,
    required this.keyword,
    required this.classFilter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onClear,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 760;

        final search = TextField(
          controller: searchController,
          focusNode: searchFocus,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Tìm theo mã hoặc tên giảng viên',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: keyword.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        );

        final filters = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FilterChip(
              label: 'Tất cả',
              value: 'all',
              selected: classFilter,
              onChanged: onFilterChanged,
            ),
            _FilterChip(
              label: '0 lớp',
              value: 'zero',
              selected: classFilter,
              onChanged: onFilterChanged,
            ),
            _FilterChip(
              label: '1–3 lớp',
              value: '1to3',
              selected: classFilter,
              onChanged: onFilterChanged,
            ),
            _FilterChip(
              label: '≥ 4 lớp',
              value: '4plus',
              selected: classFilter,
              onChanged: onFilterChanged,
            ),
          ],
        );

        final sort = PopupMenuButton<String>(
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
          child: const OutlinedButtonVisual(
            icon: Icons.sort,
            text: 'Sắp xếp',
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: filters,
                    ),
                  ),
                  const SizedBox(width: 6),
                  sort,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 5, child: search),
            const SizedBox(width: 10),
            Expanded(flex: 5, child: filters),
            const SizedBox(width: 8),
            sort,
          ],
        );
      },
    );
  }
}

class OutlinedButtonVisual extends StatelessWidget {
  final IconData icon;
  final String text;

  const OutlinedButtonVisual({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE2E8)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
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
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onChanged(value),
    );
  }
}

class _LecturerTable extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Uint8List? Function(dynamic) decodeImage;
  final Future<void> Function(String, Map<String, dynamic>) onOpen;

  const _LecturerTable({
    required this.docs,
    required this.decodeImage,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final mobile = box.maxWidth < 650;

        if (docs.isEmpty) {
          return const Card(
            child: Center(
              child: Text('Không có dữ liệu phù hợp'),
            ),
          );
        }

        if (mobile) {
          return Card(
            child: ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final document = docs[index];
                final data = document.data();
                final imageBytes = decodeImage(data['Image']);

                return ListTile(
                  onTap: () => onOpen(document.id, data),
                  leading: CircleAvatar(
                    backgroundImage:
                        imageBytes != null ? MemoryImage(imageBytes) : null,
                    child: imageBytes == null
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  title: Text(data['Fullname']?.toString() ?? ''),
                  subtitle: Text('Mã GV: ${data['IDGV'] ?? ''}'),
                  trailing: Text(
                    '${data['SumClass'] ?? 0} lớp',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          );
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                color: const Color(0xFFF8FAFC),
                child: const Row(
                  children: [
                    SizedBox(width: 50),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Họ và tên',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Mã giảng viên',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Số lớp',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(width: 36),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final document = docs[index];
                    final data = document.data();
                    final imageBytes = decodeImage(data['Image']);

                    return InkWell(
                      onTap: () => onOpen(document.id, data),
                      child: SizedBox(
                        height: 62,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: CircleAvatar(
                                    radius: 19,
                                    backgroundImage: imageBytes != null
                                        ? MemoryImage(imageBytes)
                                        : null,
                                    child: imageBytes == null
                                        ? const Icon(
                                            Icons.person_outline,
                                            size: 19,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  data['Fullname']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  data['IDGV']?.toString() ?? '',
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  data['SumClass']?.toString() ?? '0',
                                ),
                              ),
                              const SizedBox(
                                width: 36,
                                child: Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
        title: const Text(
          'Xóa giảng viên?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Dữ liệu của "$fullname" sẽ bị xóa khỏi Firestore.',
        ),
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
            icon: const Icon(Icons.delete_outline_rounded),
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
        icon: const Icon(Icons.logout_rounded, size: 32),
        title: const Text(
          'Đăng xuất?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Bạn có chắc muốn kết thúc phiên làm việc hiện tại?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ở lại'),
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
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6D5FEA)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            const Text(
              'QL Học phần',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 600)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: OutlinedButton.icon(
                onPressed: confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Đăng xuất'),
              ),
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
            final current = (data['SumClass'] as num?)?.toInt() ?? 0;
            final top = (topLecturer?['SumClass'] as num?)?.toInt() ?? -1;
            if (current > top) topLecturer = data;
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeader(colors: colors),
                    const SizedBox(height: 20),
                    _StatsSection(
                      lecturerCount: docs.length,
                      totalClasses: totalClasses,
                      topLecturer:
                          topLecturer?['Fullname']?.toString() ?? 'Chưa có',
                    ),
                    const SizedBox(height: 18),
                    _Toolbar(
                      searchController: searchController,
                      searchFocus: searchFocus,
                      keyword: keyword,
                      onSearchChanged: (value) =>
                          setState(() => keyword = value),
                      onClearSearch: () {
                        searchController.clear();
                        setState(() => keyword = '');
                        searchFocus.requestFocus();
                      },
                      onExport: () => exportDatabase(docs),
                      onAdd: addGiangVien,
                    ),
                    const SizedBox(height: 12),
                    _FilterBar(
                      selectedFilter: classFilter,
                      sortBy: sortBy,
                      onFilterChanged: (value) =>
                          setState(() => classFilter = value),
                      onSortChanged: (value) =>
                          setState(() => sortBy = value),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _LecturerPanel(
                        docs: filtered,
                        decodeImage: decodeImage,
                        onOpen: showDetail,
                      ),
                    ),
                    const SizedBox(height: 18),
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

class _DashboardHeader extends StatelessWidget {
  final ColorScheme colors;

  const _DashboardHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 600;

        return Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment:
              compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan giảng viên',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Quản lý dữ liệu và theo dõi số lớp đang phụ trách.',
                  style: TextStyle(color: Color(0xFF74798B)),
                ),
              ],
            ),
            if (compact) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF3),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFCDEFD9)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: Color(0xFF22C55E),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Firebase realtime',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int lecturerCount;
  final int totalClasses;
  final String topLecturer;

  const _StatsSection({
    required this.lecturerCount,
    required this.totalClasses,
    required this.topLecturer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 700;

        final cards = [
          _StatCard(
            icon: Icons.groups_2_rounded,
            label: 'Tổng giảng viên',
            value: lecturerCount.toString(),
            accent: const Color(0xFF5B5BD6),
            soft: const Color(0xFFEEEEFF),
          ),
          _StatCard(
            icon: Icons.auto_stories_rounded,
            label: 'Tổng số lớp',
            value: totalClasses.toString(),
            accent: const Color(0xFF0891B2),
            soft: const Color(0xFFE6F8FC),
          ),
          _StatCard(
            icon: Icons.workspace_premium_rounded,
            label: 'Nhiều lớp nhất',
            value: topLecturer,
            accent: const Color(0xFFD97706),
            soft: const Color(0xFFFFF5E6),
            smallValue: true,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                SizedBox(width: double.infinity, child: cards[i]),
                if (i < cards.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color soft;
  final bool smallValue;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.soft,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF74798B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: smallValue ? 17 : 25,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF202334),
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
  final VoidCallback onClearSearch;
  final VoidCallback onExport;
  final VoidCallback onAdd;

  const _Toolbar({
    required this.searchController,
    required this.searchFocus,
    required this.keyword,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onExport,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 700;

        final search = TextField(
          controller: searchController,
          focusNode: searchFocus,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Tìm theo mã hoặc tên giảng viên...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: keyword.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        );

        final export = OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Xuất JSON'),
        );

        final add = FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Thêm giảng viên'),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              Row(
                children: [
                  if (kIsWeb) ...[
                    Expanded(child: export),
                    const SizedBox(width: 10),
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
              const SizedBox(width: 10),
              export,
            ],
            const SizedBox(width: 10),
            add,
          ],
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selectedFilter;
  final String sortBy;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;

  const _FilterBar({
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
              child: Text('Số lớp: cao → thấp'),
            ),
            PopupMenuItem(
              value: 'classAsc',
              child: Text('Số lớp: thấp → cao'),
            ),
          ],
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFDADDEA)),
            ),
            child: const Row(
              children: [
                Icon(Icons.swap_vert_rounded, size: 19),
                SizedBox(width: 7),
                Text(
                  'Sắp xếp',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
    final active = selected == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        onSelected: (_) => onChanged(value),
        side: BorderSide(
          color: active
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFE0E3EC),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: active
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF656B7E),
        ),
      ),
    );
  }
}

class _LecturerPanel extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Uint8List? Function(dynamic) decodeImage;
  final Future<void> Function(String, Map<String, dynamic>) onOpen;

  const _LecturerPanel({
    required this.docs,
    required this.decodeImage,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách giảng viên',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${docs.length} kết quả',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: docs.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 76),
                    itemBuilder: (context, index) {
                      final document = docs[index];
                      final data = document.data();
                      final imageBytes = decodeImage(data['Image']);
                      final classes =
                          (data['SumClass'] as num?)?.toInt() ?? 0;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          hoverColor: colors.primary.withValues(alpha: 0.04),
                          onTap: () => onOpen(document.id, data),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 27,
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
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['Fullname']?.toString() ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.badge_outlined,
                                            size: 15,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            data['IDGV']?.toString() ?? '',
                                            style: const TextStyle(
                                              color: Color(0xFF74798B),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                _ClassBadge(classes: classes),
                                const SizedBox(width: 10),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4FA),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Color(0xFF74798B),
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
  }
}

class _ClassBadge extends StatelessWidget {
  final int classes;

  const _ClassBadge({required this.classes});

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;

    if (classes == 0) {
      background = const Color(0xFFF1F3F6);
      foreground = const Color(0xFF69707D);
    } else if (classes <= 3) {
      background = const Color(0xFFE8F7EE);
      foreground = const Color(0xFF15803D);
    } else {
      background = const Color(0xFFFFF2E2);
      foreground = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$classes lớp',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFF0F1F7),
            child: Icon(
              Icons.person_search_rounded,
              color: Color(0xFF7C8193),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy giảng viên',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Thử thay đổi từ khóa hoặc bộ lọc.',
            style: TextStyle(color: Color(0xFF8A8FA1)),
          ),
        ],
      ),
    );
  }
}

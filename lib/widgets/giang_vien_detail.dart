import 'dart:convert';

import 'package:flutter/material.dart';

class GiangVienDetail extends StatelessWidget {
  final Map<String, dynamic> data;

  const GiangVienDetail({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = data['Image']?.toString() ?? '';
    final classes = (data['SumClass'] as num?)?.toInt() ?? 0;

    ImageProvider? imageProvider;
    if (image.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(image));
      } catch (_) {}
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.all(18),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 470,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4F46E5), Color(0xFF6D5FEA)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.white,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: Color(0xFF5B5BD6),
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data['Fullname']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Giảng viên • QL Học phần',
                        style: TextStyle(
                          color: Color(0xFFDDE1FF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.badge_outlined,
                      label: 'Mã giảng viên',
                      value: data['IDGV']?.toString() ?? '',
                      accent: const Color(0xFF5B5BD6),
                      soft: const Color(0xFFEEEEFF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.auto_stories_outlined,
                      label: 'Số lớp phụ trách',
                      value: '$classes lớp',
                      accent: classes >= 4
                          ? const Color(0xFFD97706)
                          : const Color(0xFF0891B2),
                      soft: classes >= 4
                          ? const Color(0xFFFFF4E5)
                          : const Color(0xFFE8F8FC),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE7E9F2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dữ liệu đang được đồng bộ với Firebase Firestore.',
                        style: TextStyle(
                          color: Color(0xFF656B7E),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(
              color: colors.error.withValues(alpha: 0.35),
            ),
          ),
          onPressed: () => Navigator.pop(context, 'delete'),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Xóa'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, 'edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Chỉnh sửa'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color soft;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 11),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF74798B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

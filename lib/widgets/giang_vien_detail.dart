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
    ImageProvider? imageProvider;

    if (image.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(image));
      } catch (_) {}
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      content: SizedBox(
        width: 410,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            CircleAvatar(
              radius: 54,
              backgroundColor: colors.primaryContainer,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: colors.primary,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              data['Fullname']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Giảng viên',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.badge_outlined,
                    label: 'Mã giảng viên',
                    value: data['IDGV']?.toString() ?? '',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.class_outlined,
                    label: 'Số lớp',
                    value: data['SumClass']?.toString() ?? '0',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, 'delete'),
          icon: Icon(Icons.delete_outline, color: colors.error),
          label: Text('Xóa', style: TextStyle(color: colors.error)),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context, 'edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Sửa'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

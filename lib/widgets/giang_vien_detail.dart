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
      title: const Text('Thông tin giảng viên'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: colors.primaryContainer,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: colors.primary,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              data['Fullname']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Mã giảng viên',
              value: data['IDGV']?.toString() ?? '',
            ),
            _InfoRow(
              icon: Icons.class_outlined,
              label: 'Tổng số lớp',
              value: data['SumClass']?.toString() ?? '0',
            ),
          ],
        ),
      ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

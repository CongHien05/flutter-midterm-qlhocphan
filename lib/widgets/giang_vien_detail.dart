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
    final image = data['Image']?.toString() ?? '';

    ImageProvider? imageProvider;
    if (image.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(image));
      } catch (_) {}
    }

    return AlertDialog(
      title: const Text(
        'Thông tin giảng viên',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person_outline, size: 42)
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              data['Fullname']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Mã giảng viên'),
              trailing: Text(
                data['IDGV']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.class_outlined),
              title: const Text('Tổng số lớp'),
              trailing: Text(
                data['SumClass']?.toString() ?? '0',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, 'delete'),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Xóa'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, 'edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Sửa'),
        ),
      ],
    );
  }
}

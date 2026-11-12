import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GiangVienForm extends StatefulWidget {
  final String? idgv;
  final String? fullname;
  final String? image;
  final int? sumClass;

  const GiangVienForm({
    super.key,
    this.idgv,
    this.fullname,
    this.image,
    this.sumClass,
  });

  bool get isEdit => idgv != null;

  @override
  State<GiangVienForm> createState() => _GiangVienFormState();
}

class _GiangVienFormState extends State<GiangVienForm> {
  late final TextEditingController idgvController;
  late final TextEditingController fullnameController;

  Uint8List? imageBytes;
  String imageBase64 = '';
  String? errorMessage;
  int sumClass = 0;

  @override
  void initState() {
    super.initState();
    idgvController = TextEditingController(text: widget.idgv ?? '');
    fullnameController = TextEditingController(text: widget.fullname ?? '');
    imageBase64 = widget.image ?? '';
    sumClass = widget.sumClass ?? 0;

    if (imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (_) {
        imageBytes = null;
      }
    }
  }

  Future<void> pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      imageQuality: 25,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      imageBytes = bytes;
      imageBase64 = base64Encode(bytes);
    });
  }

  void submit() {
    final idgv = idgvController.text.trim();
    final fullname = fullnameController.text.trim();

    if (idgv.isEmpty || fullname.isEmpty) {
      setState(() {
        errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    Navigator.pop(context, {
      'IDGV': idgv,
      'Fullname': fullname,
      'Image': imageBase64,
      'SumClass': sumClass,
    });
  }

  @override
  void dispose() {
    idgvController.dispose();
    fullnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Sửa giảng viên' : 'Thêm giảng viên'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 42,
                  backgroundImage:
                      imageBytes != null ? MemoryImage(imageBytes!) : null,
                  child: imageBytes == null
                      ? const Icon(Icons.add_a_photo_outlined, size: 30)
                      : null,
                ),
              ),
              TextButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn hình ảnh'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: idgvController,
                decoration: const InputDecoration(
                  labelText: 'IDGV',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fullnameController,
                decoration: const InputDecoration(
                  labelText: 'Fullname',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'SumClass',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: sumClass > 0
                          ? () => setState(() => sumClass--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: Text(
                        '$sumClass',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => sumClass++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: submit,
          child: Text(widget.isEdit ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}

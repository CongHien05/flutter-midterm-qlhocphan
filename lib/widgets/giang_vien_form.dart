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
  late final TextEditingController sumClassController;

  Uint8List? imageBytes;
  String imageBase64 = '';
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    idgvController = TextEditingController(text: widget.idgv ?? '');
    fullnameController = TextEditingController(text: widget.fullname ?? '');
    sumClassController = TextEditingController(
      text: widget.sumClass?.toString() ?? '',
    );

    imageBase64 = widget.image ?? '';

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
    final sumClass = int.tryParse(sumClassController.text.trim());

    if (idgv.isEmpty || fullname.isEmpty || sumClass == null) {
      setState(() {
        errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    if (sumClass < 0) {
      setState(() {
        errorMessage = 'Số lớp không hợp lệ';
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
    sumClassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEdit ? 'Sửa giảng viên' : 'Thêm giảng viên',
      ),
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
              TextField(
                controller: sumClassController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SumClass',
                  prefixIcon: Icon(Icons.class_outlined),
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

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
      } catch (_) {}
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
      setState(() => errorMessage = 'Vui lòng nhập đầy đủ thông tin');
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
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.primaryContainer,
            child: Icon(
              widget.isEdit ? Icons.edit_outlined : Icons.person_add_outlined,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.isEdit ? 'Sửa giảng viên' : 'Thêm giảng viên'),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: colors.primaryContainer,
                      backgroundImage:
                          imageBytes != null ? MemoryImage(imageBytes!) : null,
                      child: imageBytes == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 42,
                              color: colors.primary,
                            )
                          : null,
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colors.primary,
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: pickImage,
                child: const Text('Chọn hình ảnh'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: idgvController,
                decoration: const InputDecoration(
                  labelText: 'Mã giảng viên',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fullnameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE3E7EF)),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.class_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tổng số lớp',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Giảm số lớp',
                      onPressed: sumClass > 0
                          ? () => setState(() => sumClass--)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '$sumClass',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Tăng số lớp',
                      onPressed: () => setState(() => sumClass++),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorMessage!,
                  style: TextStyle(color: colors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: submit,
          icon: Icon(widget.isEdit ? Icons.save_outlined : Icons.add_rounded),
          label: Text(widget.isEdit ? 'Lưu thay đổi' : 'Thêm giảng viên'),
        ),
      ],
    );
  }
}

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
      insetPadding: const EdgeInsets.all(18),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF0F0FF), Color(0xFFF8F7FF)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          backgroundImage: imageBytes != null
                              ? MemoryImage(imageBytes!)
                              : null,
                          child: imageBytes == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 38,
                                  color: colors.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Material(
                            color: colors.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: pickImage,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEdit
                                ? 'Cập nhật giảng viên'
                                : 'Thêm giảng viên mới',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Điền thông tin và ảnh đại diện của giảng viên.',
                            style: TextStyle(
                              color: Color(0xFF74798B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 18,
                            ),
                            label: const Text('Chọn hình ảnh'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(
                      icon: Icons.person_outline_rounded,
                      text: 'Thông tin cơ bản',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idgvController,
                      decoration: const InputDecoration(
                        labelText: 'Mã giảng viên',
                        hintText: 'Ví dụ: GV001',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fullnameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        hintText: 'Nhập họ tên giảng viên',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SectionLabel(
                      icon: Icons.auto_stories_outlined,
                      text: 'Số lớp phụ trách',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE4E6EF),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEEFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.class_outlined,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Tổng số lớp',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Giảm',
                            onPressed: sumClass > 0
                                ? () => setState(() => sumClass--)
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          SizedBox(
                            width: 46,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                '$sumClass',
                                key: ValueKey(sumClass),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          IconButton.filled(
                            tooltip: 'Tăng',
                            onPressed: () => setState(() => sumClass++),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: colors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: submit,
          icon: Icon(
            widget.isEdit ? Icons.save_outlined : Icons.person_add_alt_1_rounded,
          ),
          label: Text(
            widget.isEdit ? 'Lưu thay đổi' : 'Thêm giảng viên',
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

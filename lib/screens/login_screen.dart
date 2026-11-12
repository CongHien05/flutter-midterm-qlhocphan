import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;
  bool hidePassword = true;
  String? errorMessage;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await authService.login(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.code == 'invalid-email'
            ? 'Email không hợp lệ'
            : 'Email hoặc mật khẩu không đúng';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Đăng nhập thất bại';
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 820;

          if (!wide) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _LoginForm(
                    colors: colors,
                    emailController: emailController,
                    passwordController: passwordController,
                    hidePassword: hidePassword,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    onTogglePassword: () =>
                        setState(() => hidePassword = !hidePassword),
                    onLogin: login,
                    showBrand: true,
                  ),
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  color: const Color(0xFF153E75),
                  padding: const EdgeInsets.all(56),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Brand(),
                      Spacer(),
                      Text(
                        'QUẢN LÝ HỌC PHẦN',
                        style: TextStyle(
                          color: Color(0xFFBFDBFE),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Quản lý thông tin\ngiảng viên',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 22),
                      _SideInfo(
                        icon: Icons.people_outline,
                        text: 'Quản lý danh sách giảng viên',
                      ),
                      SizedBox(height: 12),
                      _SideInfo(
                        icon: Icons.class_outlined,
                        text: 'Theo dõi số lớp phụ trách',
                      ),
                      SizedBox(height: 12),
                      _SideInfo(
                        icon: Icons.storage_outlined,
                        text: 'Dữ liệu lưu trên Firebase Firestore',
                      ),
                      Spacer(),
                      Text(
                        'QLHocPhan • Flutter + Firebase',
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 70,
                      vertical: 40,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: _LoginForm(
                        colors: colors,
                        emailController: emailController,
                        passwordController: passwordController,
                        hidePassword: hidePassword,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        onTogglePassword: () =>
                            setState(() => hidePassword = !hidePassword),
                        onLogin: login,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.school_rounded, color: Colors.white, size: 30),
        SizedBox(width: 12),
        Text(
          'QLHocPhan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SideInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SideInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFBFDBFE), size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE5E7EB),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final ColorScheme colors;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool hidePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final bool showBrand;

  const _LoginForm({
    required this.colors,
    required this.emailController,
    required this.passwordController,
    required this.hidePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onLogin,
    this.showBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBrand) ...[
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                color: const Color(0xFF153E75),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'QLHocPhan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
        ],
        const Text(
          'Đăng nhập quản trị',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhập tài khoản đã được tạo trên Firebase Authentication.',
          style: TextStyle(
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Email',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'admin@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mật khẩu',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: passwordController,
          obscureText: hidePassword,
          onSubmitted: (_) {
            if (!isLoading) onLogin();
          },
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(color: colors.error),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : onLogin,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đăng nhập'),
            ),
          ),
        ),
      ],
    );
  }
}

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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 760;

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: const BorderSide(color: Color(0xFFE8EBF2)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        if (wide)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              color: colors.primaryContainer,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 54,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Quản lý học phần',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Quản lý giảng viên, số lớp và dữ liệu học phần trong một giao diện đơn giản.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: colors.onPrimaryContainer
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(wide ? 40 : 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!wide) ...[
                                  Icon(
                                    Icons.school_rounded,
                                    size: 42,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                const Text(
                                  'Chào mừng trở lại',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Đăng nhập tài khoản quản trị viên',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: passwordController,
                                  obscureText: hidePassword,
                                  onSubmitted: (_) {
                                    if (!isLoading) login();
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    prefixIcon:
                                        const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(
                                          () => hidePassword = !hidePassword,
                                        );
                                      },
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
                                  child: FilledButton.icon(
                                    onPressed: isLoading ? null : login,
                                    icon: isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.login_rounded),
                                    label: Text(
                                      isLoading
                                          ? 'Đang đăng nhập...'
                                          : 'Đăng nhập',
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

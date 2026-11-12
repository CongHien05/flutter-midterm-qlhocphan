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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F3FF),
              Color(0xFFF8F9FD),
              Color(0xFFF4F7FB),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth >= 760;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE7E9F2)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120F172A),
                          blurRadius: 36,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: wide
                        ? Row(
                            children: [
                              Expanded(child: _BrandPanel(colors: colors)),
                              Expanded(child: _LoginForm(
                                colors: colors,
                                emailController: emailController,
                                passwordController: passwordController,
                                hidePassword: hidePassword,
                                isLoading: isLoading,
                                errorMessage: errorMessage,
                                onTogglePassword: () => setState(
                                  () => hidePassword = !hidePassword,
                                ),
                                onLogin: login,
                              )),
                            ],
                          )
                        : _LoginForm(
                            colors: colors,
                            emailController: emailController,
                            passwordController: passwordController,
                            hidePassword: hidePassword,
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            onTogglePassword: () => setState(
                              () => hidePassword = !hidePassword,
                            ),
                            onLogin: login,
                            mobile: true,
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final ColorScheme colors;

  const _BrandPanel({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      padding: const EdgeInsets.all(46),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF6D5FEA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _BrandBadge(),
          SizedBox(height: 34),
          Text(
            'Quản lý học phần\nthông minh hơn.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              height: 1.18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Theo dõi giảng viên, số lớp và dữ liệu học phần trong một giao diện trực quan.',
            style: TextStyle(
              color: Color(0xFFDDE1FF),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          SizedBox(height: 30),
          _Feature(icon: Icons.bolt_rounded, text: 'Dữ liệu realtime với Firebase'),
          SizedBox(height: 12),
          _Feature(icon: Icons.tune_rounded, text: 'Tìm kiếm, lọc và sắp xếp nhanh'),
          SizedBox(height: 12),
          _Feature(icon: Icons.cloud_download_outlined, text: 'Xuất dữ liệu JSON tiện lợi'),
        ],
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'QL HỌC PHẦN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
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
  final bool mobile;

  const _LoginForm({
    required this.colors,
    required this.emailController,
    required this.passwordController,
    required this.hidePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onLogin,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(mobile ? 28 : 46),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            const _BrandBadgeMobile(),
            const SizedBox(height: 28),
          ],
          const Text(
            'Chào mừng trở lại',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đăng nhập để tiếp tục quản lý hệ thống.',
            style: TextStyle(color: Color(0xFF74798B), fontSize: 15),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email quản trị',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: hidePassword,
            onSubmitted: (_) {
              if (!isLoading) onLogin();
            },
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                errorMessage!,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onLogin,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(isLoading ? 'Đang đăng nhập...' : 'Đăng nhập'),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Firebase Authentication • Secure Admin Access',
              style: TextStyle(
                color: Color(0xFF9A9FB2),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBadgeMobile extends StatelessWidget {
  const _BrandBadgeMobile();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          backgroundColor: Color(0xFFE9E9FF),
          child: Icon(Icons.school_rounded, color: Color(0xFF5B5BD6)),
        ),
        SizedBox(width: 10),
        Text(
          'QL Học phần',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

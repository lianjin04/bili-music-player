import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/bilibili_api_service.dart';

/// 登录页面
/// 用户输入B站Cookie进行认证
class LoginPage extends StatefulWidget {
  final BilibiliApiService apiService;

  const LoginPage({super.key, required this.apiService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _cookieController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _obscureCookie = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCookie();
  }

  Future<void> _loadSavedCookie() async {
    final cookie = await _storage.read(key: 'bilibili_cookie');
    if (cookie != null && cookie.isNotEmpty) {
      _cookieController.text = cookie;
    }
  }

  Future<void> _login() async {
    final cookie = _cookieController.text.trim();
    if (cookie.isEmpty) {
      setState(() => _statusMessage = '请输入Cookie');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '正在验证...';
    });

    await widget.apiService.setCookie(cookie);
    final userInfo = await widget.apiService.getUserInfo();

    if (!mounted) return;

    if (userInfo != null) {
      final name = userInfo['name'] ?? '未知用户';
      setState(() => _statusMessage = '登录成功！欢迎 $name');
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      // 跳转到主页
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _statusMessage = 'Cookie无效或已过期，请重新获取';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cookieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Icon(
                  Icons.headphones_music,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'B站音乐播放器',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '将你的收藏夹变成私人歌单',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 40),

                // Cookie输入
                TextField(
                  controller: _cookieController,
                  obscureText: _obscureCookie,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'B站 Cookie',
                    hintText: '粘贴你的 SESSDATA...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCookie
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCookie = !_obscureCookie),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '从浏览器F12 → Network → 复制Cookie中的SESSDATA',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),

                // 状态信息
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusMessage!.contains('成功')
                            ? Colors.green
                            : _statusMessage!.contains('无效')
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                  ),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('登录', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),

                // 帮助信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            '如何获取Cookie？',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. 在浏览器中登录 bilibili.com\n'
                        '2. 按 F12 打开开发者工具\n'
                        '3. 切换到 Network（网络）选项卡\n'
                        '4. 刷新页面，点击任意请求\n'
                        '5. 在 Request Headers 中找到 Cookie\n'
                        '6. 复制包含 SESSDATA=xxx 的完整Cookie',
                        style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

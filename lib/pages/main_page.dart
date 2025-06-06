import 'package:flutter/material.dart';
import '../services/readeck_api_service.dart';
import 'home_page.dart';
import 'unread_page.dart';
import 'settings_page.dart';

class MainPage extends StatefulWidget {
  final ReadeckApiService apiService;
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const MainPage({
    super.key,
    required this.apiService,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // 页面标题列表
  final List<String> _pageTitles = [
    '今日阅读',
    '未读',
    '设置',
  ];

  // 获取当前页面
  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage(
          apiService: widget.apiService,
          onThemeChanged: widget.onThemeChanged,
          currentThemeMode: widget.currentThemeMode,
          showAppBar: false,
        );
      case 1:
        return UnreadPage(
          apiService: widget.apiService,
          showAppBar: false,
        );
      case 2:
        return SettingsPage(
          apiService: widget.apiService,
          onThemeChanged: widget.onThemeChanged,
          currentThemeMode: widget.currentThemeMode,
          showAppBar: false,
        );
      default:
        return HomePage(
          apiService: widget.apiService,
          onThemeChanged: widget.onThemeChanged,
          currentThemeMode: widget.currentThemeMode,
          showAppBar: false,
        );
    }
  }

  // 切换页面
  void _onPageSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        elevation: 4,
      ),
      drawer: _buildDrawer(context),
      body: _getCurrentPage(),
    );
  }

  // 构建左侧抽屉菜单
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 今日阅读菜单项
          ListTile(
            leading: const Icon(Icons.today),
            title: const Text(
              '今日阅读',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // 关闭抽屉
              _onPageSelected(0);
            },
            selected: _selectedIndex == 0,
            selectedTileColor:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          ),
          // 未读书签菜单项
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text(
              '未读',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // 关闭抽屉
              _onPageSelected(1);
            },
            selected: _selectedIndex == 1,
            selectedTileColor:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          ),
          // 分割线
          const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          // 设置菜单项
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text(
              '设置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // 关闭抽屉
              _onPageSelected(2);
            },
            selected: _selectedIndex == 2,
            selectedTileColor:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

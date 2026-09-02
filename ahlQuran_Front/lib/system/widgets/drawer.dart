import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Text(
              'القائمة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          _drawerItem('الرئيسية'),
          _drawerItem('الأسعار'),
          _drawerItem('المزايا'),
          _drawerItem('الدعم الفني'),
          _drawerItem('التسويق بالعمولة'),
          _drawerItem('تسجيل الدخول'),
        ],
      ),
    );
  }

  Widget _drawerItem(String title) {
    return ListTile(title: Text(title), onTap: () {});
  }
}

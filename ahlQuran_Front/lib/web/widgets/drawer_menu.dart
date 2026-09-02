import 'package:flutter/material.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  Widget _drawerItem(String title) {
    return ListTile(
      title: Text(title),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0E9D6D)),
            child: Text('القائمة',
                style: TextStyle(color: Colors.white, fontSize: 24),
                textAlign: TextAlign.center),
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
}

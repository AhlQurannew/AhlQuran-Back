import 'package:flutter/material.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  static const List<Map<String, dynamic>> _stats = [
    {'icon': Icons.school, 'label': 'عدد المدارس', 'value': '+200'},
    {'icon': Icons.group, 'label': 'عدد الطلاب', 'value': '+20000'},
    {'icon': Icons.person, 'label': 'عدد المعلمين', 'value': '+1000'},
    {'icon': Icons.tv, 'label': 'عدد الحلقات', 'value': '+1200'},
  ];
//
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        color: const Color(0xFF0E9D6D),
        child: Column(
          children: [
            Text(
              'أرقام حول النظام',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 800;
                return Flex(
                  direction: isWideScreen ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _stats
                      .map(
                        (stat) => Padding(
                          padding: isWideScreen
                              ? const EdgeInsets.symmetric(horizontal: 5)
                              : const EdgeInsets.symmetric(vertical: 10),
                          child: StatCard(stat: stat),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatefulWidget {
  final Map<String, dynamic> stat;

  const StatCard({required this.stat, super.key});

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 250,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: _isHovered ? 12 : 8,
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _isHovered ? Colors.orange : Colors.white,
              child: Icon(
                widget.stat['icon'],
                size: 36,
                color: _isHovered ? Colors.white : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.stat['label'],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.stat['value'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

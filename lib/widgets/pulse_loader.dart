import 'package:flutter/material.dart';

class PulseLoader extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String text;

  const PulseLoader({
    super.key,
    this.icon = Icons.favorite,
    this.color = const Color(0xFF2E7D32),
    this.text = 'Cargando...',
  });

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _animation,
            child: Icon(
              widget.icon,
              size: 60,
              color: widget.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: 16,
              color: widget.color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
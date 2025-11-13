import 'package:flutter/material.dart';

/// Custom painter for drawing WhatsApp-style chat bubble tails
class ChatBubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isIncoming;

  ChatBubbleTailPainter({
    required this.color,
    required this.isIncoming,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isIncoming) {
      // Tail on bottom-left for incoming messages
      path.moveTo(0, 0);
      path.quadraticBezierTo(-8, 0, -8, 8);
      path.quadraticBezierTo(-8, 12, 0, 8);
      path.close();
    } else {
      // Tail on bottom-right for outgoing messages
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(size.width + 8, 0, size.width + 8, 8);
      path.quadraticBezierTo(size.width + 8, 12, size.width, 8);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ChatBubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isIncoming != isIncoming;
  }
}

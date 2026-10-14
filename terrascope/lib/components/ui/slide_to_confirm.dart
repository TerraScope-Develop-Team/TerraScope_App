import 'package:flutter/material.dart';

class SlideToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;
  final Color baseColor;
  final Color slideColor;

  const SlideToConfirm({
    super.key,
    required this.onConfirm,
    this.text = 'Desliza para SOS',
    this.baseColor = Colors.redAccent,
    this.slideColor = Colors.white,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  double _position = 0.0;
  bool _isConfirmed = false;
  final double _height = 60.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxSlide = maxWidth - _height;

        return Container(
          width: maxWidth,
          height: _height,
          decoration: BoxDecoration(
            color: widget.baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_height / 2),
            border: Border.all(color: widget.baseColor.withOpacity(0.5), width: 2),
          ),
          child: Stack(
            children: [
              // Texto de fondo
              Center(
                child: Text(
                  _isConfirmed ? '¡SOS ENVIADO!' : widget.text,
                  style: TextStyle(
                    color: widget.baseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              // Botón deslizable
              Positioned(
                left: _position,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _position += details.delta.dx;
                      if (_position < 0) _position = 0;
                      if (_position > maxSlide) {
                        _position = maxSlide;
                        _isConfirmed = true;
                        widget.onConfirm();
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!_isConfirmed) {
                      setState(() {
                        _position = 0.0; // Vuelve al inicio si no se completó
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: _isConfirmed ? const Duration(milliseconds: 200) : Duration.zero,
                    width: _height - 4,
                    height: _height - 4,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: widget.baseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.baseColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isConfirmed ? Icons.check : Icons.keyboard_double_arrow_right,
                      color: widget.slideColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

class Waveform extends StatefulWidget {
  final bool active;
  const Waveform({super.key, required this.active});

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random();
  final List<double> _heights = List.generate(24, (_) => 0.2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(_tick);
    if (widget.active) _controller.repeat();
  }

  void _tick() {
    if (_controller.value == 1.0) {
      setState(() {
        for (var i = 0; i < _heights.length; i++) {
          _heights[i] = widget.active ? 0.15 + _random.nextDouble() * 0.85 : 0.1;
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active) {
      _controller.stop();
      setState(() {
        for (var i = 0; i < _heights.length; i++) {
          _heights[i] = 0.1;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final h in _heights)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 48 * h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

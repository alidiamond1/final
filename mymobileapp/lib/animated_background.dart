import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedBackground({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  
  @override
  void initState() {
    super.initState();
    
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background with animated gradient
        AnimatedBuilder(
          animation: Listenable.merge([_controller1, _controller2]),
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    math.sin(_controller1.value * 2 * math.pi),
                    math.cos(_controller1.value * 2 * math.pi),
                  ),
                  end: Alignment(
                    math.sin(_controller2.value * 2 * math.pi + math.pi),
                    math.cos(_controller2.value * 2 * math.pi + math.pi),
                  ),
                  colors: const [
                    Color(0xFF144BA6),
                    Color(0xFF0D3580),
                    Color(0xFF0A2A66),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Animated overlay particles
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, _) {
            return CustomPaint(
              painter: ParticlesPainter(
                progress: _controller1.value,
              ),
              child: Container(),
            );
          },
        ),
        
        // Content
        widget.child,
      ],
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final double progress;
  final List<Particle> particles = List.generate(
    30, // Number of particles
    (index) => Particle(
      position: Offset(
        math.Random().nextDouble(),
        math.Random().nextDouble(),
      ),
      radius: math.Random().nextDouble() * 3 + 1,
      alpha: math.Random().nextDouble() * 0.6 + 0.2,
    ),
  );
  
  ParticlesPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.0);
    
    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];
      
      // Calculate position based on progress
      final x = (particle.position.dx + 0.2 * math.sin(progress * 2 * math.pi + i)) * size.width;
      final y = (particle.position.dy + 0.1 * math.cos(progress * 2 * math.pi + i * 0.5)) * size.height;
      
      // Pulsate opacity
      final alpha = particle.alpha * (0.6 + 0.4 * math.sin(progress * 2 * math.pi + i * 0.2));
      
      // Draw particle
      paint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), particle.radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

class Particle {
  final Offset position; // Normalized position (0-1)
  final double radius;
  final double alpha; // Base opacity
  
  Particle({
    required this.position,
    required this.radius,
    required this.alpha,
  });
} 
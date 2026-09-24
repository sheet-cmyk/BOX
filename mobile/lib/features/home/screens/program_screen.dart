import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/jbb_button.dart';

const trainingPrograms = <String, (String, String)>{
  'boxing': (
    'Boxing Training',
    'Build stance, footwork, defense and punching technique with focused coaching. Progress from fundamentals to more advanced drills at your level.',
  ),
  'fitness': (
    'Fitness Training',
    'Improve general fitness through cardio, mobility and whole-body exercises adapted to your starting level.',
  ),
  'strength': (
    'Strength and Conditioning',
    'Develop strength, endurance and movement quality through progressive resistance work and conditioning drills.',
  ),
  'weight-loss': (
    'Weight Loss Training',
    'Build consistent exercise habits with structured activity and conditioning. Results vary; training does not guarantee weight loss or replace medical or nutritional care.',
  ),
  'self-defense': (
    'Self Defense Training',
    'Practice awareness, positioning, movement and defensive fundamentals. Training cannot guarantee safety in a real confrontation.',
  ),
};

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final program = trainingPrograms[id];
    return Scaffold(
      appBar: AppBar(title: Text(program?.$1 ?? 'Program')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            program?.$2 ?? 'Contact the gym for program details.',
            style: const TextStyle(fontSize: 18, height: 1.7),
          ),
          const SizedBox(height: 24),
          const Text('Availability and suitability are confirmed by the gym.'),
          const SizedBox(height: 24),
          JbbButton(
            label: 'View Available Sessions',
            onPressed: () => context.go('/schedule?program=$id'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/contact'),
            child: const Text('Ask the Coach'),
          ),
        ],
      ),
    );
  }
}

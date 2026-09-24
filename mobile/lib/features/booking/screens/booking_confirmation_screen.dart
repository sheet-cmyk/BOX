import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 88,
            ),
            const SizedBox(height: 24),
            Text(
              "You’re booked in.",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your session credit is reserved. See you at Junior Boy Boxing.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
            TextButton(
              onPressed: () => context.go('/bookings'),
              child: const Text('View My Bookings'),
            ),
          ],
        ),
      ),
    ),
  );
}

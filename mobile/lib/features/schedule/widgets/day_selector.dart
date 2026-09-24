import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class DaySelector extends StatelessWidget {
  const DaySelector({super.key, required this.date, required this.onChange});
  final DateTime date;
  final ValueChanged<DateTime> onChange;
  @override
  Widget build(BuildContext context) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onChange(date.subtract(const Duration(days: 7))),
              tooltip: 'Previous week',
              icon: const Icon(Icons.chevron_left),
            ),
            const Spacer(),
            const Text('Choose your training day'),
            const Spacer(),
            IconButton(
              onPressed: () => onChange(date.add(const Duration(days: 7))),
              tooltip: 'Next week',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: List.generate(7, (i) {
            final day = monday.add(Duration(days: i)),
                selected = day.day == date.day && day.month == date.month;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: DateFormat.yMMMMEEEEd().format(day),
                child: InkWell(
                  onTap: () => onChange(day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.red : AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(day).toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${day.day}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

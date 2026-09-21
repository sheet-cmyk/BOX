import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({super.key, required this.date, required this.onChange});
  final DateTime date;
  final ValueChanged<DateTime> onChange;
  @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(tooltip: 'Previous month', onPressed: () => onChange(DateTime(date.year, date.month - 1, 1)), icon: const Icon(Icons.chevron_left)), Text(DateFormat('MMMM yyyy').format(date), style: Theme.of(context).textTheme.titleLarge), IconButton(tooltip: 'Next month', onPressed: () => onChange(DateTime(date.year, date.month + 1, 1)), icon: const Icon(Icons.chevron_right))]);
}

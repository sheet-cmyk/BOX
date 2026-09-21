import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
DateTime readDate(dynamic value) => value is Timestamp ? value.toDate() : DateTime.tryParse(value?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
DateTime gymTime(DateTime date) => tz.TZDateTime.from(date, tz.getLocation('America/Los_Angeles'));
String dateLabel(DateTime date) => DateFormat('EEE, MMM d').format(gymTime(date));
String timeLabel(DateTime date) => DateFormat('h:mm a').format(gymTime(date));

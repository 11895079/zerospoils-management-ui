library;

/// Application-wide logger utility
/// Wraps the logger package for consistent logging across the app

import 'package:logger/logger.dart';

/// Singleton logger instance for the entire app
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // Number of method calls to include in stack trace
    errorMethodCount: 5, // Number of method calls for errors
    lineLength: 80, // Width of the output
    colors: true, // Use colors in console
    printEmojis: true, // Print emojis for log levels
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Logger instance for debug builds only
final debugLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: Level.debug,
);

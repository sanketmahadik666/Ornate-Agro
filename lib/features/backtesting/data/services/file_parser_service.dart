import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';

/// Service for parsing Excel and CSV input sheets
class FileParserService {
  /// Parse Excel file (.xlsx, .xls)
  static Future<Map<String, dynamic>> parseExcel(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Get first sheet
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        throw Exception('No sheets found in Excel file');
      }

      // Convert to map (first row as headers)
      final headers = <String>[];
      final data = <String, dynamic>{};

      for (var rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];
        if (row.isEmpty) continue;

        if (rowIndex == 0) {
          // First row: headers
          headers.addAll(row.map((cell) => cell?.value?.toString() ?? '').where((h) => h.isNotEmpty));
        } else {
          // Data rows
          for (var colIndex = 0; colIndex < headers.length && colIndex < row.length; colIndex++) {
            final header = headers[colIndex];
            final cellValue = row[colIndex]?.value;
            if (header.isNotEmpty && cellValue != null) {
              // If multiple rows, store as list
              if (data.containsKey(header)) {
                if (data[header] is! List) {
                  data[header] = [data[header]];
                }
                (data[header] as List).add(_parseCellValue(cellValue));
              } else {
                data[header] = _parseCellValue(cellValue);
              }
            }
          }
        }
      }

      return data;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  /// Parse CSV file
  static Future<Map<String, dynamic>> parseCsv(File file) async {
    try {
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // First row: headers
      final headers = (rows[0] as List).map((h) => h.toString()).toList();
      final data = <String, dynamic>{};

      // Process data rows
      for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex] as List;
        for (var colIndex = 0; colIndex < headers.length && colIndex < row.length; colIndex++) {
          final header = headers[colIndex];
          final cellValue = row[colIndex];
          if (header.isNotEmpty && cellValue != null) {
            // If multiple rows, store as list
            if (data.containsKey(header)) {
              if (data[header] is! List) {
                data[header] = [data[header]];
              }
              (data[header] as List).add(_parseCellValue(cellValue));
            } else {
              data[header] = _parseCellValue(cellValue);
            }
          }
        }
      }

      return data;
    } catch (e) {
      throw Exception('Failed to parse CSV file: $e');
    }
  }

  /// Parse JSON file
  static Future<Map<String, dynamic>> parseJson(File file) async {
    try {
      final content = await file.readAsString();
      // Simple JSON parsing - in production, use dart:convert
      // For now, return empty map and let caller handle JSON
      return <String, dynamic>{};
    } catch (e) {
      throw Exception('Failed to parse JSON file: $e');
    }
  }

  /// Parse file based on extension
  static Future<Map<String, dynamic>> parseFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'xlsx':
      case 'xls':
        return parseExcel(file);
      case 'csv':
        return parseCsv(file);
      case 'json':
        return parseJson(file);
      default:
        throw Exception('Unsupported file format: $extension');
    }
  }

  /// Parse cell value to appropriate type
  static dynamic _parseCellValue(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;

    // Try parsing as number
    if (RegExp(r'^-?\d+$').hasMatch(str)) {
      return int.tryParse(str);
    }
    if (RegExp(r'^-?\d+\.\d+$').hasMatch(str)) {
      return double.tryParse(str) ?? str;
    }

    // Try parsing as boolean
    if (str.toLowerCase() == 'true') return true;
    if (str.toLowerCase() == 'false') return false;

    // Try parsing as date (YYYY-MM-DD or YYYY-MM)
    if (RegExp(r'^\d{4}-\d{2}(-\d{2})?$').hasMatch(str)) {
      return str; // Return as string for now
    }

    return str;
  }

  /// Validate parsed data against expected schema
  static List<ValidationError> validateData(
    Map<String, dynamic> data,
    Map<String, FieldSchema> schema,
  ) {
    final errors = <ValidationError>[];

    for (final entry in schema.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value;

      if (!data.containsKey(fieldName)) {
        if (fieldSchema.required) {
          errors.add(ValidationError(
            field: fieldName,
            message: 'Required field missing',
            type: ValidationErrorType.error,
          ));
        }
        continue;
      }

      final value = data[fieldName];
      if (value == null && fieldSchema.required) {
        errors.add(ValidationError(
          field: fieldName,
          message: 'Required field is null',
          type: ValidationErrorType.error,
        ));
        continue;
      }

      // Type validation
      if (value != null && fieldSchema.type != null) {
        final typeMatch = _validateType(value, fieldSchema.type!);
        if (!typeMatch) {
          errors.add(ValidationError(
            field: fieldName,
            message: 'Expected ${fieldSchema.type}, got ${value.runtimeType}',
            type: ValidationErrorType.error,
          ));
        }
      }

      // Range validation
      if (value != null && fieldSchema.min != null) {
        if (value is num && value < fieldSchema.min!) {
          errors.add(ValidationError(
            field: fieldName,
            message: 'Value ${value} is less than minimum ${fieldSchema.min}',
            type: ValidationErrorType.error,
          ));
        }
      }

      if (value != null && fieldSchema.max != null) {
        if (value is num && value > fieldSchema.max!) {
          errors.add(ValidationError(
            field: fieldName,
            message: 'Value ${value} is greater than maximum ${fieldSchema.max}',
            type: ValidationErrorType.error,
          ));
        }
      }
    }

    return errors;
  }

  static bool _validateType(dynamic value, FieldType type) {
    switch (type) {
      case FieldType.string:
        return value is String;
      case FieldType.number:
        return value is num;
      case FieldType.integer:
        return value is int;
      case FieldType.double:
        return value is double;
      case FieldType.boolean:
        return value is bool;
      case FieldType.date:
        return value is String && RegExp(r'^\d{4}-\d{2}(-\d{2})?$').hasMatch(value);
      case FieldType.any:
        return true;
    }
  }
}

enum FieldType { string, number, integer, double, boolean, date, any }

class FieldSchema {
  FieldSchema({
    required this.type,
    this.required = false,
    this.min,
    this.max,
    this.pattern,
  });

  final FieldType type;
  final bool required;
  final num? min;
  final num? max;
  final String? pattern; // Regex pattern for string validation
}

class ValidationError {
  ValidationError({
    required this.field,
    required this.message,
    required this.type,
  });

  final String field;
  final String message;
  final ValidationErrorType type;
}

enum ValidationErrorType { none, warning, error }

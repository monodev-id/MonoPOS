import 'package:intl/intl.dart';

class DateTimeFormatter {
  DateTimeFormatter._();

  static String normal(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('d MMMM y').format(parsedDate);
  }

  static String normalWithClock(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('d MMMM y • HH:mm').format(parsedDate);
  }

  static String detailed(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('EEEE, d MMMM y').format(parsedDate);
  }

  static String detailedWithClock(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('EEEE, d MMMM y • HH:mm').format(parsedDate);
  }

  static String dayShorted(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('EEE, d MMMM y').format(parsedDate);
  }

  static String slashDate(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('dd/MM/y').format(parsedDate);
  }

  static String slashDateWithClock(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('dd/MM/y • HH:mm').format(parsedDate);
  }

  static String slashDateShortedYearWithClock(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('dd/MM/yy • HH:mm').format(parsedDate);
  }

  /// Sama seperti [slashDateShortedYearWithClock] tetapi hanya memakai karakter
  /// ASCII (tanpa "•") agar aman untuk printer thermal ESC/POS 58 mm.
  static String slashDateShortedYearWithClockPlain(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(parsedDate.day)}/${two(parsedDate.month)}/${two(parsedDate.year % 100)} '
        '${two(parsedDate.hour)}:${two(parsedDate.minute)}';
  }

  static String onlyDate(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('dd').format(parsedDate);
  }

  static String onlyDateAndMonth(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('dd/MM').format(parsedDate);
  }

  static String onlyMonth(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('MM').format(parsedDate);
  }

  static String onlyMonthAndYear(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('MM/yy').format(parsedDate);
  }

  static String onlyYear(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('y').format(parsedDate);
  }

  static String onlyDayShorted(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('EEE').format(parsedDate);
  }

  static String onlyClockWithDivider(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('HH:mm').format(parsedDate);
  }

  static String onlyClockWithoutDivider(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('HHmm').format(parsedDate);
  }

  static String stripDateWithClock(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('dd-MM-yyyy • HH:mm').format(parsedDate);
  }

  static String stripDate(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }

  static String onlyHour(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('H').format(parsedDate);
  }

  static String onlyMinute(String iso8601String) {
    var parsedDate = DateTime.tryParse(iso8601String);

    if (parsedDate == null) {
      return '(Invalid date format)';
    }

    return DateFormat('m').format(parsedDate);
  }
}

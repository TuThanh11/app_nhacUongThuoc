class TimeFormatHelper {
  /// Chuyển đổi từ định dạng 24h (HH:mm) sang 12h (hh:mm AM/PM)
  static String format24To12Hour(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      
      // Chuyển đổi giờ
      if (hour == 0) {
        hour = 12; // Nửa đêm
      } else if (hour > 12) {
        hour = hour - 12;
      }
      
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }
  
  /// Chuyển đổi từ định dạng 12h (hh:mm AM/PM) sang 24h (HH:mm)
  static String format12To24Hour(String time12) {
    try {
      // Tách time và period (AM/PM)
      final parts = time12.split(' ');
      if (parts.length != 2) return time12;
      
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return time12;
      
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      String period = parts[1].toUpperCase();
      
      // Chuyển đổi giờ
      if (period == 'AM') {
        if (hour == 12) {
          hour = 0; // Nửa đêm
        }
      } else { // PM
        if (hour != 12) {
          hour = hour + 12;
        }
      }
      
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time12;
    }
  }
  
  /// Chuyển đổi danh sách thời gian từ 24h sang 12h
  static List<String> formatList24To12Hour(List<String> times24) {
    return times24.map((time) => format24To12Hour(time)).toList();
  }
  
  /// Chuyển đổi danh sách thời gian từ 12h sang 24h
  static List<String> formatList12To24Hour(List<String> times12) {
    return times12.map((time) => format12To24Hour(time)).toList();
  }
}
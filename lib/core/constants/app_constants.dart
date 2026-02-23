/// App-wide constants (Req 5, 6, 9).
abstract final class AppConstants {
  static const int sessionTimeoutMinutes = 30;
  static const int contactWarningDays = 20;
  static const int contactEscalationDays = 30;
  static const int yieldDueApproachDays = 7;

  /// Days a farmer stays in Reminder before auto-escalating to Blacklist.
  static const int reminderEscalationDays = 5;
}

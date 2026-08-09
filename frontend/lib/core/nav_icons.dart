import 'package:flutter/material.dart';

IconData iconForKey(String key) {
  switch (key) {
    case 'dashboard':
      return Icons.dashboard_outlined;
    case 'patients':
      return Icons.people_outline;
    case 'appointments':
      return Icons.calendar_month_outlined;
    case 'queue':
      return Icons.format_list_numbered;
    case 'billing':
      return Icons.receipt_long_outlined;
    case 'recalls':
      return Icons.notifications_active_outlined;
    case 'records':
      return Icons.description_outlined;
    case 'staff':
      return Icons.badge_outlined;
    case 'branches':
      return Icons.account_tree_outlined;
    case 'roles':
      return Icons.admin_panel_settings_outlined;
    case 'inventory':
      return Icons.inventory_2_outlined;
    case 'reports':
      return Icons.bar_chart_outlined;
    case 'attendance':
      return Icons.fact_check_outlined;
    case 'leave':
      return Icons.event_busy_outlined;
    case 'settings':
      return Icons.settings_outlined;
    default:
      return Icons.circle_outlined;
  }
}

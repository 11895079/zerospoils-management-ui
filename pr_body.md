## Summary
- add shopping list repository ordering + telemetry source
- expand expiring soon screen tests, telemetry, and accessibility hooks
- enhance item detail wasted dialog actions and edit action button
- include settings in backup/restore export/import with rollback
- groom and update M2 planning acceptance checklists
- update copilot instructions to require todo task creation
- normalize onboarding arrow text

## Testing
- flutter analyze
- flutter test app/test/unit/backup_restore_service_test.dart
- flutter test app/test/unit/data/repositories/hive_shopping_list_repository_test.dart
- flutter test app/test/unit/data/repositories/hive_shopping_list_repository_telemetry_test.dart
- flutter test app/test/widget/item_detail_mark_wasted_test.dart
- flutter test app/test/widget/screens/item_detail_screen_test.dart
- flutter test app/test/widget/screens/expiring_today_screen_test.dart

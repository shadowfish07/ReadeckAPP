import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../helpers/migration_test_helper.dart';

void main() {
  // 初始化sqflite_ffi用于测试
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await MigrationTestHelper.cleanup();
  });

  group('Database Migration Tests', () {
    group('Version 1 to Version 2 Migration', () {
      test('should add bookmark_article table when upgrading from v1 to v2',
          () async {
        // Arrange & Act - 创建版本1数据库并升级到版本2
        final upgradedDb =
            await MigrationTestHelper.testUpgradeWithPresetData(1, 2);

        // Assert - 验证升级结果

        // 1. 验证新表已创建
        final bookmarkTableExists = await MigrationTestHelper.tableExists(
            upgradedDb, 'bookmark_article');
        expect(bookmarkTableExists, true,
            reason: 'bookmark_article table should be created');

        // 2. 验证原有表仍然存在
        final historyTableExists = await MigrationTestHelper.tableExists(
            upgradedDb, 'daily_read_history');
        expect(historyTableExists, true,
            reason: 'daily_read_history table should still exist');

        // 3. 验证原有数据保留
        final dataPreserved = await MigrationTestHelper.dataExists(
            upgradedDb, 'daily_read_history');
        expect(dataPreserved, true,
            reason: 'Existing data should be preserved');

        // 4. 验证新表可以正常使用
        await upgradedDb.insert('bookmark_article', {
          'bookmark_id': 'test_bookmark',
          'article': 'Test article content',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        final insertedData = await upgradedDb.query('bookmark_article',
            where: 'bookmark_id = ?', whereArgs: ['test_bookmark']);
        expect(insertedData.length, 1,
            reason: 'Should be able to insert data into new table');

        await upgradedDb.close();
      });

      test('should preserve all existing data during v1 to v2 migration',
          () async {
        // Arrange - 创建版本1数据库并插入多条数据
        final v1Db = await MigrationTestHelper.createDatabaseWithVersion(1);

        // 插入多条测试数据
        for (int i = 1; i <= 3; i++) {
          await v1Db.insert('daily_read_history', {
            'bookmark_ids': '["bookmark$i"]',
            'date': '2024-01-0$i',
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        await v1Db.close();

        // Act - 执行升级
        final upgradedDb = await MigrationTestHelper.testUpgrade(1, 2);

        // Assert - 验证所有数据都保留
        final allData = await upgradedDb.query('daily_read_history');
        expect(allData.length, 3,
            reason: 'All existing records should be preserved');

        // 验证数据内容正确
        for (int i = 0; i < allData.length; i++) {
          final record = allData[i];
          expect(record['date'], contains('2024-01-0'),
              reason: 'Date should be preserved');
          expect(record['bookmark_ids'], contains('bookmark'),
              reason: 'Bookmark IDs should be preserved');
        }

        await upgradedDb.close();
      });
    });

    group('Version 2 to Version 3 Migration', () {
      test('should add reading_stats table when upgrading from v2 to v3',
          () async {
        // Arrange & Act - 创建版本2数据库并升级到版本3
        final upgradedDb =
            await MigrationTestHelper.testUpgradeWithPresetData(2, 3);

        // Assert - 验证升级结果

        // 1. 验证新表已创建
        final statsTableExists =
            await MigrationTestHelper.tableExists(upgradedDb, 'reading_stats');
        expect(statsTableExists, true,
            reason: 'reading_stats table should be created');

        // 2. 验证原有表仍然存在
        final historyTableExists = await MigrationTestHelper.tableExists(
            upgradedDb, 'daily_read_history');
        expect(historyTableExists, true,
            reason: 'daily_read_history table should still exist');

        final bookmarkTableExists = await MigrationTestHelper.tableExists(
            upgradedDb, 'bookmark_article');
        expect(bookmarkTableExists, true,
            reason: 'bookmark_article table should still exist');

        // 3. 验证原有数据保留
        final historyDataPreserved = await MigrationTestHelper.dataExists(
            upgradedDb, 'daily_read_history');
        expect(historyDataPreserved, true,
            reason: 'History data should be preserved');

        final bookmarkDataPreserved = await MigrationTestHelper.dataExists(
            upgradedDb, 'bookmark_article');
        expect(bookmarkDataPreserved, true,
            reason: 'Bookmark data should be preserved');

        // 4. 验证新表可以正常使用
        await upgradedDb.insert('reading_stats', {
          'date': '2024-01-01',
          'articles_read': 5,
          'reading_time_minutes': 30,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        final insertedStats = await upgradedDb.query('reading_stats',
            where: 'date = ?', whereArgs: ['2024-01-01']);
        expect(insertedStats.length, 1,
            reason: 'Should be able to insert data into reading_stats table');
        expect(insertedStats.first['articles_read'], 5);
        expect(insertedStats.first['reading_time_minutes'], 30);

        await upgradedDb.close();
      });

      test('should preserve all existing data during v2 to v3 migration',
          () async {
        // Arrange & Act - 创建版本2数据库并升级到版本3
        final upgradedDb =
            await MigrationTestHelper.testUpgradeWithPresetData(2, 3);

        // Assert - 验证所有数据都保留
        final historyData = await upgradedDb.query('daily_read_history');
        expect(historyData.length, 1,
            reason: 'History data should be preserved');
        expect(historyData.first['date'], '2024-01-01');

        final bookmarkData = await upgradedDb.query('bookmark_article');
        expect(bookmarkData.length, 1,
            reason: 'Bookmark data should be preserved');
        expect(bookmarkData.first['bookmark_id'], 'bookmark1');
        expect(bookmarkData.first['article'], 'Test article content');

        await upgradedDb.close();
      });
    });

    group('Multi-version Migration', () {
      test('should handle direct upgrade from v1 to v3', () async {
        // Arrange & Act - 创建版本1数据库并直接升级到版本3
        final upgradedDb =
            await MigrationTestHelper.testUpgradeWithPresetData(1, 3);

        // Assert - 验证所有表都存在
        final historyTableExists = await MigrationTestHelper.tableExists(
            upgradedDb, 'daily_read_history');
        expect(historyTableExists, true,
            reason: 'daily_read_history table should exist');

        final bookmarkTableExists = await MigrationTestHelper.tableExists(
            upgradedDb, 'bookmark_article');
        expect(bookmarkTableExists, true,
            reason: 'bookmark_article table should be created');

        final statsTableExists =
            await MigrationTestHelper.tableExists(upgradedDb, 'reading_stats');
        expect(statsTableExists, true,
            reason: 'reading_stats table should be created');

        // 验证原有数据保留
        final dataPreserved = await MigrationTestHelper.dataExists(
            upgradedDb, 'daily_read_history');
        expect(dataPreserved, true,
            reason: 'Original data should be preserved');

        // 验证所有表都可以正常使用
        await upgradedDb.insert('bookmark_article', {
          'bookmark_id': 'test_bookmark',
          'article': 'Test content',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        await upgradedDb.insert('reading_stats', {
          'date': '2024-01-01',
          'articles_read': 1,
          'reading_time_minutes': 10,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        final bookmarkCount = await upgradedDb.query('bookmark_article');
        expect(bookmarkCount.length, 1);

        final statsCount = await upgradedDb.query('reading_stats');
        expect(statsCount.length, 1);

        await upgradedDb.close();
      });
    });

    group('Migration Error Handling', () {
      test('should handle database operations correctly after migration',
          () async {
        // Arrange & Act - 创建版本1数据库并升级到版本3
        final upgradedDb =
            await MigrationTestHelper.testUpgradeWithPresetData(1, 3);

        // Assert - 验证升级后数据库的完整性

        // 1. 验证所有表都存在且可以正常操作
        final allTables = [
          'daily_read_history',
          'bookmark_article',
          'reading_stats'
        ];
        for (final tableName in allTables) {
          final tableExists =
              await MigrationTestHelper.tableExists(upgradedDb, tableName);
          expect(tableExists, true,
              reason: '$tableName should exist after migration');
        }

        // 2. 验证原有数据保留
        final dataPreserved = await MigrationTestHelper.dataExists(
            upgradedDb, 'daily_read_history');
        expect(dataPreserved, true,
            reason: 'Original data should be preserved');

        // 3. 验证可以在新表中插入数据
        await upgradedDb.insert('bookmark_article', {
          'bookmark_id': 'test_after_migration',
          'article': 'Test content after migration',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        await upgradedDb.insert('reading_stats', {
          'date': '2024-01-01',
          'articles_read': 1,
          'reading_time_minutes': 10,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // 4. 验证插入的数据可以正确检索
        final bookmarkData = await upgradedDb.query('bookmark_article',
            where: 'bookmark_id = ?', whereArgs: ['test_after_migration']);
        expect(bookmarkData.length, 1,
            reason:
                'Should be able to insert and retrieve from bookmark_article');

        final statsData = await upgradedDb.query('reading_stats',
            where: 'date = ?', whereArgs: ['2024-01-01']);
        expect(statsData.length, 1,
            reason: 'Should be able to insert and retrieve from reading_stats');

        await upgradedDb.close();
      });
    });
  });
}

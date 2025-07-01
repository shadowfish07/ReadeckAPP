import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 用于测试数据库版本升级的辅助类
class MigrationTestHelper {
  static const String _testDbName = 'migration_test.db';

  /// 创建指定版本的数据库
  static Future<Database> createDatabaseWithVersion(int version) async {
    final dbPath = join(await getDatabasesPath(), _testDbName);

    // 删除现有数据库
    await deleteDatabase(dbPath);

    Database db;

    switch (version) {
      case 1:
        db = await _createV1Database(dbPath);
        break;
      case 2:
        db = await _createV2Database(dbPath);
        break;
      case 3:
        db = await _createV3Database(dbPath);
        break;
      default:
        throw ArgumentError('Unsupported database version: $version');
    }

    return db;
  }

  /// 创建版本1的数据库（只有daily_read_history表）
  static Future<Database> _createV1Database(String path) async {
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_read_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookmark_ids TEXT NOT NULL,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// 创建版本2的数据库（添加bookmark_article表）
  static Future<Database> _createV2Database(String path) async {
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // 创建daily_read_history表
        await db.execute('''
          CREATE TABLE daily_read_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookmark_ids TEXT NOT NULL,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // 创建bookmark_article表
        await db.execute('''
          CREATE TABLE bookmark_article (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookmark_id TEXT UNIQUE NOT NULL,
            article TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// 创建版本3的数据库（添加reading_stats表）
  static Future<Database> _createV3Database(String path) async {
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // 创建所有表
        await db.execute('''
          CREATE TABLE daily_read_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookmark_ids TEXT NOT NULL,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE bookmark_article (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookmark_id TEXT UNIQUE NOT NULL,
            article TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE reading_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            articles_read INTEGER NOT NULL DEFAULT 0,
            reading_time_minutes INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// 插入版本1的测试数据
  static Future<void> insertV1TestData(Database db) async {
    await db.insert('daily_read_history', {
      'bookmark_ids': '["bookmark1", "bookmark2"]',
      'date': '2024-01-01',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 插入版本2的测试数据
  static Future<void> insertV2TestData(Database db) async {
    // 插入历史数据
    await insertV1TestData(db);

    // 插入书签文章数据
    await db.insert('bookmark_article', {
      'bookmark_id': 'bookmark1',
      'article': 'Test article content',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// 验证表是否存在
  static Future<bool> tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  /// 验证数据是否保留
  static Future<bool> dataExists(Database db, String tableName) async {
    try {
      final result = await db.query(tableName, limit: 1);
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 清理测试数据库
  static Future<void> cleanup() async {
    final dbPath = join(await getDatabasesPath(), _testDbName);
    await deleteDatabase(dbPath);
  }

  /// 测试数据库升级（保留现有数据库中的数据）
  static Future<Database> testUpgrade(int fromVersion, int toVersion) async {
    final dbPath = join(await getDatabasesPath(), _testDbName);

    // 直接使用sqflite的onUpgrade回调来测试升级
    final upgradedDb = await openDatabase(
      dbPath,
      version: toVersion,
      onUpgrade: (db, oldVersion, newVersion) async {
        // 模拟DatabaseService的onUpgrade逻辑
        if (oldVersion < 2 && newVersion >= 2) {
          // 添加bookmark_article表
          await db.execute('''
            CREATE TABLE bookmark_article (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              bookmark_id TEXT UNIQUE NOT NULL,
              article TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 3 && newVersion >= 3) {
          // 添加reading_stats表
          await db.execute('''
            CREATE TABLE reading_stats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              articles_read INTEGER NOT NULL DEFAULT 0,
              reading_time_minutes INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );

    return upgradedDb;
  }

  /// 测试数据库升级（从头创建并插入预设数据）
  static Future<Database> testUpgradeWithPresetData(
      int fromVersion, int toVersion) async {
    final dbPath = join(await getDatabasesPath(), _testDbName);

    // 删除现有数据库
    await deleteDatabase(dbPath);

    // 创建旧版本数据库
    Database oldDb = await createDatabaseWithVersion(fromVersion);

    // 插入测试数据
    switch (fromVersion) {
      case 1:
        await insertV1TestData(oldDb);
        break;
      case 2:
        await insertV2TestData(oldDb);
        break;
    }

    await oldDb.close();

    // 使用testUpgrade方法进行升级
    return await testUpgrade(fromVersion, toVersion);
  }
}

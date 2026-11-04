import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../database_constants.dart';

/// Model representing a queued mutation waiting to be synced with the server.
class OutboxItem {
  final String id;
  final String shopId;
  final String entityType;
  final String entityId;
  final String action;
  final Map<String, dynamic> payload;
  final String status;
  final int retryCount;
  final int maxRetries;
  final String? lastError;
  final int createdAt;
  final int? processedAt;

  OutboxItem({
    required this.id,
    required this.shopId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    this.status = DatabaseConstants.outboxPending,
    this.retryCount = 0,
    this.maxRetries = 10,
    this.lastError,
    required this.createdAt,
    this.processedAt,
  });

  factory OutboxItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> payloadMap = {};
    try {
      payloadMap = jsonDecode(map['payload'] as String? ?? '{}') as Map<String, dynamic>;
    } catch (_) {}

    return OutboxItem(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      action: map['action'] as String,
      payload: payloadMap,
      status: map['status'] as String? ?? DatabaseConstants.outboxPending,
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
      maxRetries: (map['max_retries'] as num?)?.toInt() ?? 10,
      lastError: map['last_error'] as String?,
      createdAt: (map['created_at'] as num).toInt(),
      processedAt: (map['processed_at'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'payload': jsonEncode(payload),
      'status': status,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'last_error': lastError,
      'created_at': createdAt,
      'processed_at': processedAt,
    };
  }
}

/// DAO for managing the local sync outbox queue.
class SyncOutboxDao {
  const SyncOutboxDao();

  Database get _db => AppDatabase.instance.database;

  /// Enqueue a mutation to be pushed to the cloud server.
  /// Generates a UUID v4 as both the item ID and idempotency key.
  Future<String> enqueue({
    required String shopId,
    required String entityType,
    required String entityId,
    required String action,
    required Map<String, dynamic> payload,
    Transaction? txn,
  }) async {
    const uuid = Uuid();
    final outboxId = uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final item = OutboxItem(
      id: outboxId,
      shopId: shopId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
      createdAt: now,
    );

    final executor = txn ?? _db;
    await executor.insert(
      DatabaseConstants.tableSyncOutbox,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return outboxId;
  }

  /// Get pending mutations in chronological order up to [limit].
  Future<List<OutboxItem>> getPending({int limit = 50}) async {
    final rows = await _db.query(
      DatabaseConstants.tableSyncOutbox,
      where: 'status = ?',
      whereArgs: [DatabaseConstants.outboxPending],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map(OutboxItem.fromMap).toList();
  }

  /// Mark items as in-flight during an active network sync push.
  Future<void> markInFlight(List<String> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await _db.update(
      DatabaseConstants.tableSyncOutbox,
      {'status': DatabaseConstants.outboxInFlight},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Delete completed outbox items after successful server ack.
  Future<void> deleteCompleted(List<String> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await _db.delete(
      DatabaseConstants.tableSyncOutbox,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Mark an item failed and increment retry count with exponential backoff.
  Future<void> recordFailure(String id, String error) async {
    await _db.rawUpdate('''
      UPDATE ${DatabaseConstants.tableSyncOutbox}
      SET status = CASE WHEN retry_count + 1 >= max_retries THEN 'FAILED' ELSE 'PENDING' END,
          retry_count = retry_count + 1,
          last_error = ?
      WHERE id = ?
    ''', [error, id]);
  }

  /// Return total pending count.
  Future<int> getPendingCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${DatabaseConstants.tableSyncOutbox} WHERE status = ?',
      [DatabaseConstants.outboxPending],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}


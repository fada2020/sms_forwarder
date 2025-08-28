import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact_model.dart';
import '../models/sms_log_model.dart';
import '../models/sender_filter_model.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../models/sender_group_mapping_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sms_forwarder.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phoneNumber TEXT NOT NULL UNIQUE,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE sms_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT NOT NULL,
        message TEXT NOT NULL,
        forwardedTo TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        success INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE sender_filters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phoneNumber TEXT NOT NULL UNIQUE,
        displayName TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE group_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId INTEGER NOT NULL,
        contactId INTEGER NOT NULL,
        addedAt INTEGER NOT NULL,
        FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (contactId) REFERENCES contacts (id) ON DELETE CASCADE,
        UNIQUE(groupId, contactId)
      )
    ''');

    await db.execute('''
      CREATE TABLE sender_group_mappings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderFilterId INTEGER NOT NULL,
        groupId INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (senderFilterId) REFERENCES sender_filters (id) ON DELETE CASCADE,
        FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE CASCADE,
        UNIQUE(senderFilterId, groupId)
      )
    ''');
  }

  // Contact operations
  Future<int> insertContact(ContactModel contact) async {
    final db = await database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<ContactModel>> getAllContacts() async {
    final db = await database;
    final maps = await db.query('contacts', orderBy: 'name ASC');
    return maps.map((map) => ContactModel.fromMap(map)).toList();
  }

  Future<List<ContactModel>> getActiveContacts() async {
    final db = await database;
    final maps = await db.query(
      'contacts',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ContactModel.fromMap(map)).toList();
  }

  Future<int> updateContact(ContactModel contact) async {
    final db = await database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // SMS Log operations
  Future<int> insertSmsLog(SmsLogModel smsLog) async {
    final db = await database;
    return await db.insert('sms_logs', smsLog.toMap());
  }

  Future<List<SmsLogModel>> getAllSmsLogs() async {
    final db = await database;
    final maps = await db.query('sms_logs', orderBy: 'timestamp DESC');
    return maps.map((map) => SmsLogModel.fromMap(map)).toList();
  }

  Future<List<SmsLogModel>> getRecentSmsLogs(int limit) async {
    final db = await database;
    final maps = await db.query(
      'sms_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => SmsLogModel.fromMap(map)).toList();
  }

  Future<int> clearSmsLogs() async {
    final db = await database;
    return await db.delete('sms_logs');
  }

  // Sender Filter operations
  Future<int> insertSenderFilter(SenderFilterModel senderFilter) async {
    final db = await database;
    return await db.insert('sender_filters', senderFilter.toMap());
  }

  Future<List<SenderFilterModel>> getAllSenderFilters() async {
    final db = await database;
    final maps = await db.query('sender_filters', orderBy: 'displayName ASC');
    return maps.map((map) => SenderFilterModel.fromMap(map)).toList();
  }

  Future<List<SenderFilterModel>> getActiveSenderFilters() async {
    final db = await database;
    final maps = await db.query(
      'sender_filters',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'displayName ASC',
    );
    return maps.map((map) => SenderFilterModel.fromMap(map)).toList();
  }

  Future<int> updateSenderFilter(SenderFilterModel senderFilter) async {
    final db = await database;
    return await db.update(
      'sender_filters',
      senderFilter.toMap(),
      where: 'id = ?',
      whereArgs: [senderFilter.id],
    );
  }

  Future<int> deleteSenderFilter(int id) async {
    final db = await database;
    return await db.delete('sender_filters', where: 'id = ?', whereArgs: [id]);
  }

  // Group operations
  Future<int> insertGroup(GroupModel group) async {
    final db = await database;
    return await db.insert('groups', group.toMap());
  }

  Future<List<GroupModel>> getAllGroups() async {
    final db = await database;
    final maps = await db.query('groups', orderBy: 'name ASC');
    return maps.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<List<GroupModel>> getActiveGroups() async {
    final db = await database;
    final maps = await db.query(
      'groups',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<int> updateGroup(GroupModel group) async {
    final db = await database;
    return await db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;
    return await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  // Group Member operations
  Future<int> insertGroupMember(GroupMemberModel groupMember) async {
    final db = await database;
    return await db.insert('group_members', groupMember.toMap());
  }

  Future<List<ContactModel>> getGroupMembers(int groupId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT c.* FROM contacts c
      INNER JOIN group_members gm ON c.id = gm.contactId
      WHERE gm.groupId = ? AND c.isActive = 1
      ORDER BY c.name ASC
    ''', [groupId]);
    return maps.map((map) => ContactModel.fromMap(map)).toList();
  }

  Future<List<GroupModel>> getContactGroups(int contactId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT g.* FROM groups g
      INNER JOIN group_members gm ON g.id = gm.groupId
      WHERE gm.contactId = ? AND g.isActive = 1
      ORDER BY g.name ASC
    ''', [contactId]);
    return maps.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<int> removeGroupMember(int groupId, int contactId) async {
    final db = await database;
    return await db.delete(
      'group_members',
      where: 'groupId = ? AND contactId = ?',
      whereArgs: [groupId, contactId],
    );
  }

  Future<bool> isContactInGroup(int groupId, int contactId) async {
    final db = await database;
    final result = await db.query(
      'group_members',
      where: 'groupId = ? AND contactId = ?',
      whereArgs: [groupId, contactId],
    );
    return result.isNotEmpty;
  }

  // Sender Group Mapping operations
  Future<int> insertSenderGroupMapping(SenderGroupMappingModel mapping) async {
    final db = await database;
    return await db.insert('sender_group_mappings', mapping.toMap());
  }

  Future<List<GroupModel>> getSenderGroups(int senderFilterId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT g.* FROM groups g
      INNER JOIN sender_group_mappings sgm ON g.id = sgm.groupId
      WHERE sgm.senderFilterId = ? AND g.isActive = 1
      ORDER BY g.name ASC
    ''', [senderFilterId]);
    return maps.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<List<SenderFilterModel>> getGroupSenders(int groupId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT sf.* FROM sender_filters sf
      INNER JOIN sender_group_mappings sgm ON sf.id = sgm.senderFilterId
      WHERE sgm.groupId = ? AND sf.isActive = 1
      ORDER BY sf.displayName ASC
    ''', [groupId]);
    return maps.map((map) => SenderFilterModel.fromMap(map)).toList();
  }

  Future<int> removeSenderGroupMapping(int senderFilterId, int groupId) async {
    final db = await database;
    return await db.delete(
      'sender_group_mappings',
      where: 'senderFilterId = ? AND groupId = ?',
      whereArgs: [senderFilterId, groupId],
    );
  }

  Future<bool> isSenderMappedToGroup(int senderFilterId, int groupId) async {
    final db = await database;
    final result = await db.query(
      'sender_group_mappings',
      where: 'senderFilterId = ? AND groupId = ?',
      whereArgs: [senderFilterId, groupId],
    );
    return result.isNotEmpty;
  }

  Future<List<ContactModel>> getContactsForSender(String senderPhoneNumber) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT c.* FROM contacts c
      INNER JOIN group_members gm ON c.id = gm.contactId
      INNER JOIN sender_group_mappings sgm ON gm.groupId = sgm.groupId
      INNER JOIN sender_filters sf ON sgm.senderFilterId = sf.id
      WHERE sf.phoneNumber = ? AND sf.isActive = 1 AND c.isActive = 1
      ORDER BY c.name ASC
    ''', [senderPhoneNumber]);
    return maps.map((map) => ContactModel.fromMap(map)).toList();
  }
}
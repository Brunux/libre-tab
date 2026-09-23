// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SongsTable extends Songs with TableInfo<$SongsTable, SongEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _songKeyMeta = const VerificationMeta(
    'songKey',
  );
  @override
  late final GeneratedColumn<String> songKey = GeneratedColumn<String>(
    'song_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capoMeta = const VerificationMeta('capo');
  @override
  late final GeneratedColumn<int> capo = GeneratedColumn<int>(
    'capo',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _scrollSpeedMeta = const VerificationMeta(
    'scrollSpeed',
  );
  @override
  late final GeneratedColumn<int> scrollSpeed = GeneratedColumn<int>(
    'scroll_speed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artist,
    songKey,
    capo,
    body,
    favorite,
    scrollSpeed,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SongEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('song_key')) {
      context.handle(
        _songKeyMeta,
        songKey.isAcceptableOrUnknown(data['song_key']!, _songKeyMeta),
      );
    }
    if (data.containsKey('capo')) {
      context.handle(
        _capoMeta,
        capo.isAcceptableOrUnknown(data['capo']!, _capoMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('scroll_speed')) {
      context.handle(
        _scrollSpeedMeta,
        scrollSpeed.isAcceptableOrUnknown(
          data['scroll_speed']!,
          _scrollSpeedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SongEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SongEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      songKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_key'],
      ),
      capo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}capo'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      scrollSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scroll_speed'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SongsTable createAlias(String alias) {
    return $SongsTable(attachedDatabase, alias);
  }
}

class SongEntry extends DataClass implements Insertable<SongEntry> {
  final int id;
  final String title;
  final String artist;
  final String? songKey;
  final int? capo;
  final String body;
  final bool favorite;

  /// Auto-scroll speed last used for this song (song view).
  final int? scrollSpeed;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SongEntry({
    required this.id,
    required this.title,
    required this.artist,
    this.songKey,
    this.capo,
    required this.body,
    required this.favorite,
    this.scrollSpeed,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    if (!nullToAbsent || songKey != null) {
      map['song_key'] = Variable<String>(songKey);
    }
    if (!nullToAbsent || capo != null) {
      map['capo'] = Variable<int>(capo);
    }
    map['body'] = Variable<String>(body);
    map['favorite'] = Variable<bool>(favorite);
    if (!nullToAbsent || scrollSpeed != null) {
      map['scroll_speed'] = Variable<int>(scrollSpeed);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SongsCompanion toCompanion(bool nullToAbsent) {
    return SongsCompanion(
      id: Value(id),
      title: Value(title),
      artist: Value(artist),
      songKey: songKey == null && nullToAbsent
          ? const Value.absent()
          : Value(songKey),
      capo: capo == null && nullToAbsent ? const Value.absent() : Value(capo),
      body: Value(body),
      favorite: Value(favorite),
      scrollSpeed: scrollSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(scrollSpeed),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SongEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SongEntry(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      songKey: serializer.fromJson<String?>(json['songKey']),
      capo: serializer.fromJson<int?>(json['capo']),
      body: serializer.fromJson<String>(json['body']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      scrollSpeed: serializer.fromJson<int?>(json['scrollSpeed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'songKey': serializer.toJson<String?>(songKey),
      'capo': serializer.toJson<int?>(capo),
      'body': serializer.toJson<String>(body),
      'favorite': serializer.toJson<bool>(favorite),
      'scrollSpeed': serializer.toJson<int?>(scrollSpeed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SongEntry copyWith({
    int? id,
    String? title,
    String? artist,
    Value<String?> songKey = const Value.absent(),
    Value<int?> capo = const Value.absent(),
    String? body,
    bool? favorite,
    Value<int?> scrollSpeed = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SongEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    songKey: songKey.present ? songKey.value : this.songKey,
    capo: capo.present ? capo.value : this.capo,
    body: body ?? this.body,
    favorite: favorite ?? this.favorite,
    scrollSpeed: scrollSpeed.present ? scrollSpeed.value : this.scrollSpeed,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SongEntry copyWithCompanion(SongsCompanion data) {
    return SongEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      songKey: data.songKey.present ? data.songKey.value : this.songKey,
      capo: data.capo.present ? data.capo.value : this.capo,
      body: data.body.present ? data.body.value : this.body,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      scrollSpeed: data.scrollSpeed.present
          ? data.scrollSpeed.value
          : this.scrollSpeed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SongEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('songKey: $songKey, ')
          ..write('capo: $capo, ')
          ..write('body: $body, ')
          ..write('favorite: $favorite, ')
          ..write('scrollSpeed: $scrollSpeed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    artist,
    songKey,
    capo,
    body,
    favorite,
    scrollSpeed,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SongEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.songKey == this.songKey &&
          other.capo == this.capo &&
          other.body == this.body &&
          other.favorite == this.favorite &&
          other.scrollSpeed == this.scrollSpeed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SongsCompanion extends UpdateCompanion<SongEntry> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> artist;
  final Value<String?> songKey;
  final Value<int?> capo;
  final Value<String> body;
  final Value<bool> favorite;
  final Value<int?> scrollSpeed;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SongsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.songKey = const Value.absent(),
    this.capo = const Value.absent(),
    this.body = const Value.absent(),
    this.favorite = const Value.absent(),
    this.scrollSpeed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SongsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.artist = const Value.absent(),
    this.songKey = const Value.absent(),
    this.capo = const Value.absent(),
    required String body,
    this.favorite = const Value.absent(),
    this.scrollSpeed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       body = Value(body);
  static Insertable<SongEntry> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? songKey,
    Expression<int>? capo,
    Expression<String>? body,
    Expression<bool>? favorite,
    Expression<int>? scrollSpeed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (songKey != null) 'song_key': songKey,
      if (capo != null) 'capo': capo,
      if (body != null) 'body': body,
      if (favorite != null) 'favorite': favorite,
      if (scrollSpeed != null) 'scroll_speed': scrollSpeed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SongsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? artist,
    Value<String?>? songKey,
    Value<int?>? capo,
    Value<String>? body,
    Value<bool>? favorite,
    Value<int?>? scrollSpeed,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SongsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      songKey: songKey ?? this.songKey,
      capo: capo ?? this.capo,
      body: body ?? this.body,
      favorite: favorite ?? this.favorite,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (songKey.present) {
      map['song_key'] = Variable<String>(songKey.value);
    }
    if (capo.present) {
      map['capo'] = Variable<int>(capo.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (scrollSpeed.present) {
      map['scroll_speed'] = Variable<int>(scrollSpeed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SongsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('songKey: $songKey, ')
          ..write('capo: $capo, ')
          ..write('body: $body, ')
          ..write('favorite: $favorite, ')
          ..write('scrollSpeed: $scrollSpeed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SongsTable songs = $SongsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [songs];
}

typedef $$SongsTableCreateCompanionBuilder =
    SongsCompanion Function({
      Value<int> id,
      required String title,
      Value<String> artist,
      Value<String?> songKey,
      Value<int?> capo,
      required String body,
      Value<bool> favorite,
      Value<int?> scrollSpeed,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SongsTableUpdateCompanionBuilder =
    SongsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> artist,
      Value<String?> songKey,
      Value<int?> capo,
      Value<String> body,
      Value<bool> favorite,
      Value<int?> scrollSpeed,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SongsTableFilterComposer extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get songKey => $composableBuilder(
    column: $table.songKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capo => $composableBuilder(
    column: $table.capo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scrollSpeed => $composableBuilder(
    column: $table.scrollSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SongsTableOrderingComposer
    extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get songKey => $composableBuilder(
    column: $table.songKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capo => $composableBuilder(
    column: $table.capo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scrollSpeed => $composableBuilder(
    column: $table.scrollSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get songKey =>
      $composableBuilder(column: $table.songKey, builder: (column) => column);

  GeneratedColumn<int> get capo =>
      $composableBuilder(column: $table.capo, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<int> get scrollSpeed => $composableBuilder(
    column: $table.scrollSpeed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SongsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SongsTable,
          SongEntry,
          $$SongsTableFilterComposer,
          $$SongsTableOrderingComposer,
          $$SongsTableAnnotationComposer,
          $$SongsTableCreateCompanionBuilder,
          $$SongsTableUpdateCompanionBuilder,
          (SongEntry, BaseReferences<_$AppDatabase, $SongsTable, SongEntry>),
          SongEntry,
          PrefetchHooks Function()
        > {
  $$SongsTableTableManager(_$AppDatabase db, $SongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String?> songKey = const Value.absent(),
                Value<int?> capo = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int?> scrollSpeed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SongsCompanion(
                id: id,
                title: title,
                artist: artist,
                songKey: songKey,
                capo: capo,
                body: body,
                favorite: favorite,
                scrollSpeed: scrollSpeed,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String> artist = const Value.absent(),
                Value<String?> songKey = const Value.absent(),
                Value<int?> capo = const Value.absent(),
                required String body,
                Value<bool> favorite = const Value.absent(),
                Value<int?> scrollSpeed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SongsCompanion.insert(
                id: id,
                title: title,
                artist: artist,
                songKey: songKey,
                capo: capo,
                body: body,
                favorite: favorite,
                scrollSpeed: scrollSpeed,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SongsTable, SongEntry>(table),
                  BaseReferences<_$AppDatabase, $SongsTable, SongEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SongsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SongsTable,
      SongEntry,
      $$SongsTableFilterComposer,
      $$SongsTableOrderingComposer,
      $$SongsTableAnnotationComposer,
      $$SongsTableCreateCompanionBuilder,
      $$SongsTableUpdateCompanionBuilder,
      (SongEntry, BaseReferences<_$AppDatabase, $SongsTable, SongEntry>),
      SongEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SongsTableTableManager get songs =>
      $$SongsTableTableManager(_db, _db.songs);
}

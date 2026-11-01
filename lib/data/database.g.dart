// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VisitedCountriesTable extends VisitedCountries
    with TableInfo<$VisitedCountriesTable, VisitedCountry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitedCountriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _isoCodeMeta = const VerificationMeta(
    'isoCode',
  );
  @override
  late final GeneratedColumn<String> isoCode = GeneratedColumn<String>(
    'iso_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitedAtMeta = const VerificationMeta(
    'visitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
    'visited_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [isoCode, visitedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visited_countries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitedCountry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('iso_code')) {
      context.handle(
        _isoCodeMeta,
        isoCode.isAcceptableOrUnknown(data['iso_code']!, _isoCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_isoCodeMeta);
    }
    if (data.containsKey('visited_at')) {
      context.handle(
        _visitedAtMeta,
        visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {isoCode};
  @override
  VisitedCountry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitedCountry(
      isoCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iso_code'],
      )!,
      visitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_at'],
      )!,
    );
  }

  @override
  $VisitedCountriesTable createAlias(String alias) {
    return $VisitedCountriesTable(attachedDatabase, alias);
  }
}

class VisitedCountry extends DataClass implements Insertable<VisitedCountry> {
  final String isoCode;
  final DateTime visitedAt;
  const VisitedCountry({required this.isoCode, required this.visitedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['iso_code'] = Variable<String>(isoCode);
    map['visited_at'] = Variable<DateTime>(visitedAt);
    return map;
  }

  VisitedCountriesCompanion toCompanion(bool nullToAbsent) {
    return VisitedCountriesCompanion(
      isoCode: Value(isoCode),
      visitedAt: Value(visitedAt),
    );
  }

  factory VisitedCountry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitedCountry(
      isoCode: serializer.fromJson<String>(json['isoCode']),
      visitedAt: serializer.fromJson<DateTime>(json['visitedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'isoCode': serializer.toJson<String>(isoCode),
      'visitedAt': serializer.toJson<DateTime>(visitedAt),
    };
  }

  VisitedCountry copyWith({String? isoCode, DateTime? visitedAt}) =>
      VisitedCountry(
        isoCode: isoCode ?? this.isoCode,
        visitedAt: visitedAt ?? this.visitedAt,
      );
  VisitedCountry copyWithCompanion(VisitedCountriesCompanion data) {
    return VisitedCountry(
      isoCode: data.isoCode.present ? data.isoCode.value : this.isoCode,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitedCountry(')
          ..write('isoCode: $isoCode, ')
          ..write('visitedAt: $visitedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(isoCode, visitedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitedCountry &&
          other.isoCode == this.isoCode &&
          other.visitedAt == this.visitedAt);
}

class VisitedCountriesCompanion extends UpdateCompanion<VisitedCountry> {
  final Value<String> isoCode;
  final Value<DateTime> visitedAt;
  final Value<int> rowid;
  const VisitedCountriesCompanion({
    this.isoCode = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitedCountriesCompanion.insert({
    required String isoCode,
    this.visitedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : isoCode = Value(isoCode);
  static Insertable<VisitedCountry> custom({
    Expression<String>? isoCode,
    Expression<DateTime>? visitedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (isoCode != null) 'iso_code': isoCode,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitedCountriesCompanion copyWith({
    Value<String>? isoCode,
    Value<DateTime>? visitedAt,
    Value<int>? rowid,
  }) {
    return VisitedCountriesCompanion(
      isoCode: isoCode ?? this.isoCode,
      visitedAt: visitedAt ?? this.visitedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (isoCode.present) {
      map['iso_code'] = Variable<String>(isoCode.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitedCountriesCompanion(')
          ..write('isoCode: $isoCode, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VisitedCountriesTable visitedCountries = $VisitedCountriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [visitedCountries];
}

typedef $$VisitedCountriesTableCreateCompanionBuilder =
    VisitedCountriesCompanion Function({
      required String isoCode,
      Value<DateTime> visitedAt,
      Value<int> rowid,
    });
typedef $$VisitedCountriesTableUpdateCompanionBuilder =
    VisitedCountriesCompanion Function({
      Value<String> isoCode,
      Value<DateTime> visitedAt,
      Value<int> rowid,
    });

class $$VisitedCountriesTableFilterComposer
    extends Composer<_$AppDatabase, $VisitedCountriesTable> {
  $$VisitedCountriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get isoCode => $composableBuilder(
    column: $table.isoCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisitedCountriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitedCountriesTable> {
  $$VisitedCountriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get isoCode => $composableBuilder(
    column: $table.isoCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitedCountriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitedCountriesTable> {
  $$VisitedCountriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get isoCode =>
      $composableBuilder(column: $table.isoCode, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);
}

class $$VisitedCountriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitedCountriesTable,
          VisitedCountry,
          $$VisitedCountriesTableFilterComposer,
          $$VisitedCountriesTableOrderingComposer,
          $$VisitedCountriesTableAnnotationComposer,
          $$VisitedCountriesTableCreateCompanionBuilder,
          $$VisitedCountriesTableUpdateCompanionBuilder,
          (
            VisitedCountry,
            BaseReferences<
              _$AppDatabase,
              $VisitedCountriesTable,
              VisitedCountry
            >,
          ),
          VisitedCountry,
          PrefetchHooks Function()
        > {
  $$VisitedCountriesTableTableManager(
    _$AppDatabase db,
    $VisitedCountriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitedCountriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitedCountriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitedCountriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> isoCode = const Value.absent(),
                Value<DateTime> visitedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitedCountriesCompanion(
                isoCode: isoCode,
                visitedAt: visitedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String isoCode,
                Value<DateTime> visitedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitedCountriesCompanion.insert(
                isoCode: isoCode,
                visitedAt: visitedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VisitedCountriesTable, VisitedCountry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $VisitedCountriesTable,
                    VisitedCountry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisitedCountriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitedCountriesTable,
      VisitedCountry,
      $$VisitedCountriesTableFilterComposer,
      $$VisitedCountriesTableOrderingComposer,
      $$VisitedCountriesTableAnnotationComposer,
      $$VisitedCountriesTableCreateCompanionBuilder,
      $$VisitedCountriesTableUpdateCompanionBuilder,
      (
        VisitedCountry,
        BaseReferences<_$AppDatabase, $VisitedCountriesTable, VisitedCountry>,
      ),
      VisitedCountry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VisitedCountriesTableTableManager get visitedCountries =>
      $$VisitedCountriesTableTableManager(_db, _db.visitedCountries);
}

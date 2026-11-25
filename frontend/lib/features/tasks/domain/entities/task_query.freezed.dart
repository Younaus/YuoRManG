// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskScope {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskScope);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskScope()';
}


}

/// @nodoc
class $TaskScopeCopyWith<$Res>  {
$TaskScopeCopyWith(TaskScope _, $Res Function(TaskScope) __);
}


/// Adds pattern-matching-related methods to [TaskScope].
extension TaskScopePatterns on TaskScope {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AllTasksScope value)?  all,TResult Function( UncategorizedScope value)?  uncategorized,TResult Function( CategoryScope value)?  category,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AllTasksScope() when all != null:
return all(_that);case UncategorizedScope() when uncategorized != null:
return uncategorized(_that);case CategoryScope() when category != null:
return category(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AllTasksScope value)  all,required TResult Function( UncategorizedScope value)  uncategorized,required TResult Function( CategoryScope value)  category,}){
final _that = this;
switch (_that) {
case AllTasksScope():
return all(_that);case UncategorizedScope():
return uncategorized(_that);case CategoryScope():
return category(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AllTasksScope value)?  all,TResult? Function( UncategorizedScope value)?  uncategorized,TResult? Function( CategoryScope value)?  category,}){
final _that = this;
switch (_that) {
case AllTasksScope() when all != null:
return all(_that);case UncategorizedScope() when uncategorized != null:
return uncategorized(_that);case CategoryScope() when category != null:
return category(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  all,TResult Function()?  uncategorized,TResult Function( String categoryId)?  category,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AllTasksScope() when all != null:
return all();case UncategorizedScope() when uncategorized != null:
return uncategorized();case CategoryScope() when category != null:
return category(_that.categoryId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  all,required TResult Function()  uncategorized,required TResult Function( String categoryId)  category,}) {final _that = this;
switch (_that) {
case AllTasksScope():
return all();case UncategorizedScope():
return uncategorized();case CategoryScope():
return category(_that.categoryId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  all,TResult? Function()?  uncategorized,TResult? Function( String categoryId)?  category,}) {final _that = this;
switch (_that) {
case AllTasksScope() when all != null:
return all();case UncategorizedScope() when uncategorized != null:
return uncategorized();case CategoryScope() when category != null:
return category(_that.categoryId);case _:
  return null;

}
}

}

/// @nodoc


class AllTasksScope implements TaskScope {
  const AllTasksScope();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllTasksScope);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskScope.all()';
}


}




/// @nodoc


class UncategorizedScope implements TaskScope {
  const UncategorizedScope();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UncategorizedScope);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskScope.uncategorized()';
}


}




/// @nodoc


class CategoryScope implements TaskScope {
  const CategoryScope(this.categoryId);
  

 final  String categoryId;

/// Create a copy of TaskScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryScopeCopyWith<CategoryScope> get copyWith => _$CategoryScopeCopyWithImpl<CategoryScope>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryScope&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId);

@override
String toString() {
  return 'TaskScope.category(categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class $CategoryScopeCopyWith<$Res> implements $TaskScopeCopyWith<$Res> {
  factory $CategoryScopeCopyWith(CategoryScope value, $Res Function(CategoryScope) _then) = _$CategoryScopeCopyWithImpl;
@useResult
$Res call({
 String categoryId
});




}
/// @nodoc
class _$CategoryScopeCopyWithImpl<$Res>
    implements $CategoryScopeCopyWith<$Res> {
  _$CategoryScopeCopyWithImpl(this._self, this._then);

  final CategoryScope _self;
  final $Res Function(CategoryScope) _then;

/// Create a copy of TaskScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categoryId = null,}) {
  return _then(CategoryScope(
null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TaskQuery {

 TaskScope get scope; TaskStatus? get status; TaskSort get sort;/// Kategori seçiliyken alt kategorilerin görevleri de dahil edilsin mi.
 bool get includeSubcategories;/// Başlıkta kelime öneki araması (sunucuda; büyük/küçük harf ve Türkçe karakter duyarsız).
 String? get search;/// Bitiş tarihi aralığı (iki uç dahil). Verilirse tarihsiz görevler hariç kalır ve
/// sonuçlar bitiş tarihine göre (yakından uzağa) sıralanır — takvim görünümü.
 DateTime? get dueFrom; DateTime? get dueTo; int get limit; String? get cursor;
/// Create a copy of TaskQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskQueryCopyWith<TaskQuery> get copyWith => _$TaskQueryCopyWithImpl<TaskQuery>(this as TaskQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskQuery&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.status, status) || other.status == status)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.includeSubcategories, includeSubcategories) || other.includeSubcategories == includeSubcategories)&&(identical(other.search, search) || other.search == search)&&(identical(other.dueFrom, dueFrom) || other.dueFrom == dueFrom)&&(identical(other.dueTo, dueTo) || other.dueTo == dueTo)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.cursor, cursor) || other.cursor == cursor));
}


@override
int get hashCode => Object.hash(runtimeType,scope,status,sort,includeSubcategories,search,dueFrom,dueTo,limit,cursor);

@override
String toString() {
  return 'TaskQuery(scope: $scope, status: $status, sort: $sort, includeSubcategories: $includeSubcategories, search: $search, dueFrom: $dueFrom, dueTo: $dueTo, limit: $limit, cursor: $cursor)';
}


}

/// @nodoc
abstract mixin class $TaskQueryCopyWith<$Res>  {
  factory $TaskQueryCopyWith(TaskQuery value, $Res Function(TaskQuery) _then) = _$TaskQueryCopyWithImpl;
@useResult
$Res call({
 TaskScope scope, TaskStatus? status, TaskSort sort, bool includeSubcategories, String? search, DateTime? dueFrom, DateTime? dueTo, int limit, String? cursor
});


$TaskScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$TaskQueryCopyWithImpl<$Res>
    implements $TaskQueryCopyWith<$Res> {
  _$TaskQueryCopyWithImpl(this._self, this._then);

  final TaskQuery _self;
  final $Res Function(TaskQuery) _then;

/// Create a copy of TaskQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? status = freezed,Object? sort = null,Object? includeSubcategories = null,Object? search = freezed,Object? dueFrom = freezed,Object? dueTo = freezed,Object? limit = null,Object? cursor = freezed,}) {
  return _then(_self.copyWith(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as TaskScope,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as TaskSort,includeSubcategories: null == includeSubcategories ? _self.includeSubcategories : includeSubcategories // ignore: cast_nullable_to_non_nullable
as bool,search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String?,dueFrom: freezed == dueFrom ? _self.dueFrom : dueFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dueTo: freezed == dueTo ? _self.dueTo : dueTo // ignore: cast_nullable_to_non_nullable
as DateTime?,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of TaskQuery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskScopeCopyWith<$Res> get scope {
  
  return $TaskScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [TaskQuery].
extension TaskQueryPatterns on TaskQuery {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskQuery() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskQuery value)  $default,){
final _that = this;
switch (_that) {
case _TaskQuery():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskQuery value)?  $default,){
final _that = this;
switch (_that) {
case _TaskQuery() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TaskScope scope,  TaskStatus? status,  TaskSort sort,  bool includeSubcategories,  String? search,  DateTime? dueFrom,  DateTime? dueTo,  int limit,  String? cursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskQuery() when $default != null:
return $default(_that.scope,_that.status,_that.sort,_that.includeSubcategories,_that.search,_that.dueFrom,_that.dueTo,_that.limit,_that.cursor);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TaskScope scope,  TaskStatus? status,  TaskSort sort,  bool includeSubcategories,  String? search,  DateTime? dueFrom,  DateTime? dueTo,  int limit,  String? cursor)  $default,) {final _that = this;
switch (_that) {
case _TaskQuery():
return $default(_that.scope,_that.status,_that.sort,_that.includeSubcategories,_that.search,_that.dueFrom,_that.dueTo,_that.limit,_that.cursor);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TaskScope scope,  TaskStatus? status,  TaskSort sort,  bool includeSubcategories,  String? search,  DateTime? dueFrom,  DateTime? dueTo,  int limit,  String? cursor)?  $default,) {final _that = this;
switch (_that) {
case _TaskQuery() when $default != null:
return $default(_that.scope,_that.status,_that.sort,_that.includeSubcategories,_that.search,_that.dueFrom,_that.dueTo,_that.limit,_that.cursor);case _:
  return null;

}
}

}

/// @nodoc


class _TaskQuery implements TaskQuery {
  const _TaskQuery({this.scope = const TaskScope.all(), this.status, this.sort = TaskSort.createdAt, this.includeSubcategories = false, this.search, this.dueFrom, this.dueTo, this.limit = 50, this.cursor});
  

@override@JsonKey() final  TaskScope scope;
@override final  TaskStatus? status;
@override@JsonKey() final  TaskSort sort;
/// Kategori seçiliyken alt kategorilerin görevleri de dahil edilsin mi.
@override@JsonKey() final  bool includeSubcategories;
/// Başlıkta kelime öneki araması (sunucuda; büyük/küçük harf ve Türkçe karakter duyarsız).
@override final  String? search;
/// Bitiş tarihi aralığı (iki uç dahil). Verilirse tarihsiz görevler hariç kalır ve
/// sonuçlar bitiş tarihine göre (yakından uzağa) sıralanır — takvim görünümü.
@override final  DateTime? dueFrom;
@override final  DateTime? dueTo;
@override@JsonKey() final  int limit;
@override final  String? cursor;

/// Create a copy of TaskQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskQueryCopyWith<_TaskQuery> get copyWith => __$TaskQueryCopyWithImpl<_TaskQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskQuery&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.status, status) || other.status == status)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.includeSubcategories, includeSubcategories) || other.includeSubcategories == includeSubcategories)&&(identical(other.search, search) || other.search == search)&&(identical(other.dueFrom, dueFrom) || other.dueFrom == dueFrom)&&(identical(other.dueTo, dueTo) || other.dueTo == dueTo)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.cursor, cursor) || other.cursor == cursor));
}


@override
int get hashCode => Object.hash(runtimeType,scope,status,sort,includeSubcategories,search,dueFrom,dueTo,limit,cursor);

@override
String toString() {
  return 'TaskQuery(scope: $scope, status: $status, sort: $sort, includeSubcategories: $includeSubcategories, search: $search, dueFrom: $dueFrom, dueTo: $dueTo, limit: $limit, cursor: $cursor)';
}


}

/// @nodoc
abstract mixin class _$TaskQueryCopyWith<$Res> implements $TaskQueryCopyWith<$Res> {
  factory _$TaskQueryCopyWith(_TaskQuery value, $Res Function(_TaskQuery) _then) = __$TaskQueryCopyWithImpl;
@override @useResult
$Res call({
 TaskScope scope, TaskStatus? status, TaskSort sort, bool includeSubcategories, String? search, DateTime? dueFrom, DateTime? dueTo, int limit, String? cursor
});


@override $TaskScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$TaskQueryCopyWithImpl<$Res>
    implements _$TaskQueryCopyWith<$Res> {
  __$TaskQueryCopyWithImpl(this._self, this._then);

  final _TaskQuery _self;
  final $Res Function(_TaskQuery) _then;

/// Create a copy of TaskQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = null,Object? status = freezed,Object? sort = null,Object? includeSubcategories = null,Object? search = freezed,Object? dueFrom = freezed,Object? dueTo = freezed,Object? limit = null,Object? cursor = freezed,}) {
  return _then(_TaskQuery(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as TaskScope,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as TaskSort,includeSubcategories: null == includeSubcategories ? _self.includeSubcategories : includeSubcategories // ignore: cast_nullable_to_non_nullable
as bool,search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String?,dueFrom: freezed == dueFrom ? _self.dueFrom : dueFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dueTo: freezed == dueTo ? _self.dueTo : dueTo // ignore: cast_nullable_to_non_nullable
as DateTime?,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TaskQuery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskScopeCopyWith<$Res> get scope {
  
  return $TaskScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

// dart format on

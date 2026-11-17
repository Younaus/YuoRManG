// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskDraft {

 String get title; String get description; TaskStatus get status; DateTime? get dueDate; String? get categoryId;
/// Create a copy of TaskDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDraftCopyWith<TaskDraft> get copyWith => _$TaskDraftCopyWithImpl<TaskDraft>(this as TaskDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,status,dueDate,categoryId);

@override
String toString() {
  return 'TaskDraft(title: $title, description: $description, status: $status, dueDate: $dueDate, categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class $TaskDraftCopyWith<$Res>  {
  factory $TaskDraftCopyWith(TaskDraft value, $Res Function(TaskDraft) _then) = _$TaskDraftCopyWithImpl;
@useResult
$Res call({
 String title, String description, TaskStatus status, DateTime? dueDate, String? categoryId
});




}
/// @nodoc
class _$TaskDraftCopyWithImpl<$Res>
    implements $TaskDraftCopyWith<$Res> {
  _$TaskDraftCopyWithImpl(this._self, this._then);

  final TaskDraft _self;
  final $Res Function(TaskDraft) _then;

/// Create a copy of TaskDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? status = null,Object? dueDate = freezed,Object? categoryId = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskDraft].
extension TaskDraftPatterns on TaskDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskDraft value)  $default,){
final _that = this;
switch (_that) {
case _TaskDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskDraft value)?  $default,){
final _that = this;
switch (_that) {
case _TaskDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  TaskStatus status,  DateTime? dueDate,  String? categoryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDraft() when $default != null:
return $default(_that.title,_that.description,_that.status,_that.dueDate,_that.categoryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  TaskStatus status,  DateTime? dueDate,  String? categoryId)  $default,) {final _that = this;
switch (_that) {
case _TaskDraft():
return $default(_that.title,_that.description,_that.status,_that.dueDate,_that.categoryId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  TaskStatus status,  DateTime? dueDate,  String? categoryId)?  $default,) {final _that = this;
switch (_that) {
case _TaskDraft() when $default != null:
return $default(_that.title,_that.description,_that.status,_that.dueDate,_that.categoryId);case _:
  return null;

}
}

}

/// @nodoc


class _TaskDraft implements TaskDraft {
  const _TaskDraft({required this.title, this.description = '', this.status = TaskStatus.todo, this.dueDate, this.categoryId});
  

@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  TaskStatus status;
@override final  DateTime? dueDate;
@override final  String? categoryId;

/// Create a copy of TaskDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDraftCopyWith<_TaskDraft> get copyWith => __$TaskDraftCopyWithImpl<_TaskDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,status,dueDate,categoryId);

@override
String toString() {
  return 'TaskDraft(title: $title, description: $description, status: $status, dueDate: $dueDate, categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class _$TaskDraftCopyWith<$Res> implements $TaskDraftCopyWith<$Res> {
  factory _$TaskDraftCopyWith(_TaskDraft value, $Res Function(_TaskDraft) _then) = __$TaskDraftCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, TaskStatus status, DateTime? dueDate, String? categoryId
});




}
/// @nodoc
class __$TaskDraftCopyWithImpl<$Res>
    implements _$TaskDraftCopyWith<$Res> {
  __$TaskDraftCopyWithImpl(this._self, this._then);

  final _TaskDraft _self;
  final $Res Function(_TaskDraft) _then;

/// Create a copy of TaskDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? status = null,Object? dueDate = freezed,Object? categoryId = freezed,}) {
  return _then(_TaskDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

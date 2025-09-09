// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 String get uid; String get firstName; String get lastName; String get email; String get mobileNumber; String get gender; DateTime get dateOfBirth; String get currentAddress; String get district; String get subdistrict; List<String> get communities; String get bloodGroup; bool get isDonor; bool get isEmergencyDonor; String get token; String? get createdAt; bool get isOnline; String get image;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.mobileNumber, mobileNumber) || other.mobileNumber == mobileNumber)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.currentAddress, currentAddress) || other.currentAddress == currentAddress)&&(identical(other.district, district) || other.district == district)&&(identical(other.subdistrict, subdistrict) || other.subdistrict == subdistrict)&&const DeepCollectionEquality().equals(other.communities, communities)&&(identical(other.bloodGroup, bloodGroup) || other.bloodGroup == bloodGroup)&&(identical(other.isDonor, isDonor) || other.isDonor == isDonor)&&(identical(other.isEmergencyDonor, isEmergencyDonor) || other.isEmergencyDonor == isEmergencyDonor)&&(identical(other.token, token) || other.token == token)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,firstName,lastName,email,mobileNumber,gender,dateOfBirth,currentAddress,district,subdistrict,const DeepCollectionEquality().hash(communities),bloodGroup,isDonor,isEmergencyDonor,token,createdAt,isOnline,image);

@override
String toString() {
  return 'UserModel(uid: $uid, firstName: $firstName, lastName: $lastName, email: $email, mobileNumber: $mobileNumber, gender: $gender, dateOfBirth: $dateOfBirth, currentAddress: $currentAddress, district: $district, subdistrict: $subdistrict, communities: $communities, bloodGroup: $bloodGroup, isDonor: $isDonor, isEmergencyDonor: $isEmergencyDonor, token: $token, createdAt: $createdAt, isOnline: $isOnline, image: $image)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String uid, String firstName, String lastName, String email, String mobileNumber, String gender, DateTime dateOfBirth, String currentAddress, String district, String subdistrict, List<String> communities, String bloodGroup, bool isDonor, bool isEmergencyDonor, String token, String? createdAt, bool isOnline, String image
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? mobileNumber = null,Object? gender = null,Object? dateOfBirth = null,Object? currentAddress = null,Object? district = null,Object? subdistrict = null,Object? communities = null,Object? bloodGroup = null,Object? isDonor = null,Object? isEmergencyDonor = null,Object? token = null,Object? createdAt = freezed,Object? isOnline = null,Object? image = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,mobileNumber: null == mobileNumber ? _self.mobileNumber : mobileNumber // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime,currentAddress: null == currentAddress ? _self.currentAddress : currentAddress // ignore: cast_nullable_to_non_nullable
as String,district: null == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String,subdistrict: null == subdistrict ? _self.subdistrict : subdistrict // ignore: cast_nullable_to_non_nullable
as String,communities: null == communities ? _self.communities : communities // ignore: cast_nullable_to_non_nullable
as List<String>,bloodGroup: null == bloodGroup ? _self.bloodGroup : bloodGroup // ignore: cast_nullable_to_non_nullable
as String,isDonor: null == isDonor ? _self.isDonor : isDonor // ignore: cast_nullable_to_non_nullable
as bool,isEmergencyDonor: null == isEmergencyDonor ? _self.isEmergencyDonor : isEmergencyDonor // ignore: cast_nullable_to_non_nullable
as bool,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String firstName,  String lastName,  String email,  String mobileNumber,  String gender,  DateTime dateOfBirth,  String currentAddress,  String district,  String subdistrict,  List<String> communities,  String bloodGroup,  bool isDonor,  bool isEmergencyDonor,  String token,  String? createdAt,  bool isOnline,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.uid,_that.firstName,_that.lastName,_that.email,_that.mobileNumber,_that.gender,_that.dateOfBirth,_that.currentAddress,_that.district,_that.subdistrict,_that.communities,_that.bloodGroup,_that.isDonor,_that.isEmergencyDonor,_that.token,_that.createdAt,_that.isOnline,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String firstName,  String lastName,  String email,  String mobileNumber,  String gender,  DateTime dateOfBirth,  String currentAddress,  String district,  String subdistrict,  List<String> communities,  String bloodGroup,  bool isDonor,  bool isEmergencyDonor,  String token,  String? createdAt,  bool isOnline,  String image)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.uid,_that.firstName,_that.lastName,_that.email,_that.mobileNumber,_that.gender,_that.dateOfBirth,_that.currentAddress,_that.district,_that.subdistrict,_that.communities,_that.bloodGroup,_that.isDonor,_that.isEmergencyDonor,_that.token,_that.createdAt,_that.isOnline,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String firstName,  String lastName,  String email,  String mobileNumber,  String gender,  DateTime dateOfBirth,  String currentAddress,  String district,  String subdistrict,  List<String> communities,  String bloodGroup,  bool isDonor,  bool isEmergencyDonor,  String token,  String? createdAt,  bool isOnline,  String image)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.uid,_that.firstName,_that.lastName,_that.email,_that.mobileNumber,_that.gender,_that.dateOfBirth,_that.currentAddress,_that.district,_that.subdistrict,_that.communities,_that.bloodGroup,_that.isDonor,_that.isEmergencyDonor,_that.token,_that.createdAt,_that.isOnline,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({required this.uid, required this.firstName, required this.lastName, required this.email, required this.mobileNumber, required this.gender, required this.dateOfBirth, required this.currentAddress, required this.district, required this.subdistrict, required final  List<String> communities, required this.bloodGroup, required this.isDonor, required this.isEmergencyDonor, required this.token, required this.createdAt, required this.isOnline, required this.image}): _communities = communities;
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  String uid;
@override final  String firstName;
@override final  String lastName;
@override final  String email;
@override final  String mobileNumber;
@override final  String gender;
@override final  DateTime dateOfBirth;
@override final  String currentAddress;
@override final  String district;
@override final  String subdistrict;
 final  List<String> _communities;
@override List<String> get communities {
  if (_communities is EqualUnmodifiableListView) return _communities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_communities);
}

@override final  String bloodGroup;
@override final  bool isDonor;
@override final  bool isEmergencyDonor;
@override final  String token;
@override final  String? createdAt;
@override final  bool isOnline;
@override final  String image;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.mobileNumber, mobileNumber) || other.mobileNumber == mobileNumber)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.currentAddress, currentAddress) || other.currentAddress == currentAddress)&&(identical(other.district, district) || other.district == district)&&(identical(other.subdistrict, subdistrict) || other.subdistrict == subdistrict)&&const DeepCollectionEquality().equals(other._communities, _communities)&&(identical(other.bloodGroup, bloodGroup) || other.bloodGroup == bloodGroup)&&(identical(other.isDonor, isDonor) || other.isDonor == isDonor)&&(identical(other.isEmergencyDonor, isEmergencyDonor) || other.isEmergencyDonor == isEmergencyDonor)&&(identical(other.token, token) || other.token == token)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,firstName,lastName,email,mobileNumber,gender,dateOfBirth,currentAddress,district,subdistrict,const DeepCollectionEquality().hash(_communities),bloodGroup,isDonor,isEmergencyDonor,token,createdAt,isOnline,image);

@override
String toString() {
  return 'UserModel(uid: $uid, firstName: $firstName, lastName: $lastName, email: $email, mobileNumber: $mobileNumber, gender: $gender, dateOfBirth: $dateOfBirth, currentAddress: $currentAddress, district: $district, subdistrict: $subdistrict, communities: $communities, bloodGroup: $bloodGroup, isDonor: $isDonor, isEmergencyDonor: $isEmergencyDonor, token: $token, createdAt: $createdAt, isOnline: $isOnline, image: $image)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String uid, String firstName, String lastName, String email, String mobileNumber, String gender, DateTime dateOfBirth, String currentAddress, String district, String subdistrict, List<String> communities, String bloodGroup, bool isDonor, bool isEmergencyDonor, String token, String? createdAt, bool isOnline, String image
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? mobileNumber = null,Object? gender = null,Object? dateOfBirth = null,Object? currentAddress = null,Object? district = null,Object? subdistrict = null,Object? communities = null,Object? bloodGroup = null,Object? isDonor = null,Object? isEmergencyDonor = null,Object? token = null,Object? createdAt = freezed,Object? isOnline = null,Object? image = null,}) {
  return _then(_UserModel(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,mobileNumber: null == mobileNumber ? _self.mobileNumber : mobileNumber // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime,currentAddress: null == currentAddress ? _self.currentAddress : currentAddress // ignore: cast_nullable_to_non_nullable
as String,district: null == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String,subdistrict: null == subdistrict ? _self.subdistrict : subdistrict // ignore: cast_nullable_to_non_nullable
as String,communities: null == communities ? _self._communities : communities // ignore: cast_nullable_to_non_nullable
as List<String>,bloodGroup: null == bloodGroup ? _self.bloodGroup : bloodGroup // ignore: cast_nullable_to_non_nullable
as String,isDonor: null == isDonor ? _self.isDonor : isDonor // ignore: cast_nullable_to_non_nullable
as bool,isEmergencyDonor: null == isEmergencyDonor ? _self.isEmergencyDonor : isEmergencyDonor // ignore: cast_nullable_to_non_nullable
as bool,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

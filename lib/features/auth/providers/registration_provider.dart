import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/geohash.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/repository_providers.dart';

class RegistrationState {
  final DateTime? dob;
  final String? gender;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? bloodGroup;
  final bool isDonor;
  final String? donorError;
  final XFile? pickedImage;
  final bool isLoading;

  const RegistrationState({
    this.dob,
    this.gender,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.bloodGroup,
    this.isDonor = false,
    this.donorError,
    this.pickedImage,
    this.isLoading = false,
  });

  RegistrationState copyWith({
    DateTime? dob,
    String? gender,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? bloodGroup,
    bool? isDonor,
    String? donorError,
    XFile? pickedImage,
    bool? isLoading,
  }) {
    return RegistrationState(
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      isDonor: isDonor ?? this.isDonor,
      donorError: donorError ?? this.donorError,
      pickedImage: pickedImage ?? this.pickedImage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final registrationProvider =
    NotifierProvider<RegistrationNotifier, RegistrationState>(
  RegistrationNotifier.new,
);

class RegistrationNotifier extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  void setDob(DateTime? v) => state = state.copyWith(dob: v);

  void setGender(String? v) => state = state.copyWith(gender: v);

  void setBloodGroup(String? v) => state = state.copyWith(bloodGroup: v);

  void setLocation(double lat, double lon, String address) =>
      state = state.copyWith(
        latitude: lat,
        longitude: lon,
        locationAddress: address,
      );

  void setDonor(bool v) => state = state.copyWith(isDonor: v, donorError: null);

  void setDonorError(String? v) => state = state.copyWith(donorError: v);

  void clearDonorError() => state = state.copyWith(donorError: null);

  String? validateDonorEligibility(DateTime? dob) {
    if (dob == null) return 'Date of Birth is required';
    if (_calculateAge(dob) < 18) {
      return 'You must be at least 18 years old to register as a donor.';
    }
    return null;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final compressed = await _compressImage(File(pickedFile.path));
      state = state.copyWith(pickedImage: compressed);
    }
  }

  Future<XFile?> _compressImage(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final isPng = ext == 'png';
    final format = isPng ? CompressFormat.png : CompressFormat.jpeg;
    final newExt = isPng ? 'png' : 'jpg';
    final targetPath =
        '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$newExt';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 500,
      minHeight: 500,
      format: format,
    );
    return result != null ? XFile(result.path) : null;
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<String> _uploadImage(File file, String uid) async {
    final storageRepo = ref.read(storageRepositoryProvider);
    return await storageRepo.uploadFile(file, 'users/$uid.jpg');
  }

  Future<UserCredential> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String mobileNumber,
  }) async {
    state = state.copyWith(isLoading: true, donorError: null);

    try {
      final userCredential = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password);

      final uid = userCredential.user!.uid;
      String imageUrl = '';

      if (state.pickedImage != null) {
        imageUrl = await _uploadImage(File(state.pickedImage!.path), uid);
      }

      final createdAt = DateTime.now().toIso8601String();
      final token =
          await ref.read(firebaseDataSourceProvider).messaging.getToken();

      final geohash = (state.latitude != null && state.longitude != null)
          ? Geohash.encode(state.latitude!, state.longitude!)
          : null;

      final savedAddresses = <AddressModel>[];
      if (state.latitude != null && state.longitude != null && geohash != null) {
        savedAddresses.add(
          AddressModel(
            id: const Uuid().v4(),
            label: 'Home',
            latitude: state.latitude!,
            longitude: state.longitude!,
            geohash: geohash,
            addressText: state.locationAddress ?? 'Selected Location',
          ),
        );
      }

      final user = UserModel(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobileNumber: PhoneUtils.toCanonical(mobileNumber),
        gender: state.gender!,
        dateOfBirth: state.dob!,
        communities: [],
        bloodGroup: state.bloodGroup!,
        isDonor: state.isDonor,
        isEmergencyDonor: false,
        token: token ?? '',
        createdAt: createdAt,
        isOnline: false,
        image: imageUrl,
        latitude: state.latitude,
        longitude: state.longitude,
        geohash: geohash,
        locationAddress: state.locationAddress,
        savedAddresses: savedAddresses,
      );

      await ref.read(userRepositoryProvider).createUser(uid, user.toJson());

      state = state.copyWith(isLoading: false);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuth Error: ${e.code} - ${e.message}');
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      log('Registration Error: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

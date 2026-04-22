import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart' hide AppUser;
import '../../domain/entities/app_user.dart' show AppUser, UserRole, PartnerInfo;
import '../models/app_user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<User?> get firebaseAuthStateChanges;
  Future<AppUserModel> signInWithEmailAndPassword(String email, String password);
  Future<AppUserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    PartnerInfo? partnerInfo,
  });
  Future<void> signOut();
  Future<void> sendEmailVerification();
  Future<void> sendPasswordResetEmail(String email);
  Future<AppUserModel> getUserProfile(String uid);
  Future<AppUserModel> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    PartnerInfo? partnerInfo,
  });
  Future<void> deleteAccount();
  User? get currentFirebaseUser;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // Firestore collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  //  Auth State Stream
  // ──────────────────────────────────────────────
  @override
  Stream<User?> get firebaseAuthStateChanges =>
      _firebaseAuth.authStateChanges();

  @override
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // ──────────────────────────────────────────────
  //  Sign In
  // ──────────────────────────────────────────────
  @override
  Future<AppUserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    // Update last login timestamp in Firestore
    await _usersCollection.doc(user.uid).update({
      'last_login_at': FieldValue.serverTimestamp(),
      'email_verified': user.emailVerified,
    });

    return getUserProfile(user.uid);
  }

  // ──────────────────────────────────────────────
  //  Create Account
  // ──────────────────────────────────────────────
  @override
  Future<AppUserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    PartnerInfo? partnerInfo,
  }) async {
    // 1. Create Firebase Auth user
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    // 2. Update display name in Firebase Auth
    await user.updateDisplayName(displayName);

    // 3. Build Firestore document
    final now = DateTime.now();
    final userModel = AppUserModel(
      uid: user.uid,
      email: email.trim(),
      displayName: displayName,
      role: role,
      emailVerified: false,
      createdAt: now,
      lastLoginAt: now,
      partnerInfo: partnerInfo != null
          ? PartnerInfoModel(
              businessName: partnerInfo.businessName,
              businessNameAr: partnerInfo.businessNameAr,
              partnerType: partnerInfo.partnerType,
              businessPhone: partnerInfo.businessPhone,
              businessAddress: partnerInfo.businessAddress,
            )
          : null,
    );

    // 4. Save to Firestore
    await _usersCollection.doc(user.uid).set(userModel.toJson());

    // 5. Send email verification
    await user.sendEmailVerification();

    return userModel;
  }

  // ──────────────────────────────────────────────
  //  Sign Out
  // ──────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ──────────────────────────────────────────────
  //  Email Verification
  // ──────────────────────────────────────────────
  @override
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  // ──────────────────────────────────────────────
  //  Password Reset
  // ──────────────────────────────────────────────
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // ──────────────────────────────────────────────
  //  Get User Profile from Firestore
  // ──────────────────────────────────────────────
  @override
  Future<AppUserModel> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('user-not-found');
    }

    return AppUserModel.fromFirestore(doc);
  }

  // ──────────────────────────────────────────────
  //  Update Profile
  // ──────────────────────────────────────────────
  @override
  Future<AppUserModel> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    PartnerInfo? partnerInfo,
  }) async {
    final updates = <String, dynamic>{};

    if (displayName != null) {
      updates['display_name'] = displayName;
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      updates['photo_url'] = photoUrl;
      await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
    }
    if (partnerInfo != null) {
      updates['partner_info'] = PartnerInfoModel(
        businessName: partnerInfo.businessName,
        businessNameAr: partnerInfo.businessNameAr,
        partnerType: partnerInfo.partnerType,
        businessPhone: partnerInfo.businessPhone,
        businessAddress: partnerInfo.businessAddress,
        businessLogoUrl: partnerInfo.businessLogoUrl,
        isVerified: partnerInfo.isVerified,
        rating: partnerInfo.rating,
        reviewCount: partnerInfo.reviewCount,
        totalBookings: partnerInfo.totalBookings,
        isActive: partnerInfo.isActive,
      ).toJson();
    }

    if (updates.isNotEmpty) {
      await _usersCollection.doc(uid).update(updates);
    }

    return getUserProfile(uid);
  }

  // ──────────────────────────────────────────────
  //  Delete Account
  // ──────────────────────────────────────────────
  @override
  Future<void> deleteAccount() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      await _usersCollection.doc(uid).delete();
    }
    await _firebaseAuth.currentUser?.delete();
  }
}

// ════════════════════════════════════════════════════════════
//  MockAuthRemoteDataSource
//  يُستخدم عندما لا يكون Firebase مُهيّأً بعد
//  يُصدر null فوراً → AuthBloc يُصدر Unauthenticated → الانتقال لصفحة الدخول
// ════════════════════════════════════════════════════════════
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Stream<User?> get firebaseAuthStateChanges =>
      Stream.value(null); // يُصدر "غير مسجل دخول" فوراً

  @override
  User? get currentFirebaseUser => null;

  @override
  Future<AppUserModel> signInWithEmailAndPassword(String email, String password) =>
      throw UnimplementedError('Firebase غير مُهيّأ. شغّل: flutterfire configure');

  @override
  Future<AppUserModel> createUserWithEmailAndPassword({
    required String email, required String password,
    required String displayName, required UserRole role, PartnerInfo? partnerInfo,
  }) => throw UnimplementedError('Firebase غير مُهيّأ');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUserModel> getUserProfile(String uid) =>
      throw UnimplementedError('Firebase غير مُهيّأ');

  @override
  Future<AppUserModel> updateUserProfile({
    required String uid, String? displayName, String? photoUrl, PartnerInfo? partnerInfo,
  }) => throw UnimplementedError('Firebase غير مُهيّأ');

  @override
  Future<void> deleteAccount() async {}
}

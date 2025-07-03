import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final payoutMethodsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      sellerId,
    ) async* {
      if (sellerId.isEmpty) yield [];
      final snapshots =
          FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .collection('payoutMethods')
              .snapshots();
      await for (final snap in snapshots) {
        yield snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    });

final payoutsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      sellerId,
    ) async* {
      if (sellerId.isEmpty) yield [];
      final snapshots =
          FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .collection('payouts')
              .orderBy('date', descending: true)
              .snapshots();
      await for (final snap in snapshots) {
        yield snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    });

final payoutProvider = StateNotifierProvider<PayoutNotifier, void>(
  (ref) => PayoutNotifier(),
);

class PayoutNotifier extends StateNotifier<void> {
  PayoutNotifier() : super(null);

  Future<void> addPayoutMethod(
    String sellerId,
    String type,
    String details,
  ) async {
    final ref =
        FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .collection('payoutMethods')
            .doc();
    await ref.set({'type': type, 'details': details});
  }

  Future<void> deletePayoutMethod(String sellerId, String methodId) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .collection('payoutMethods')
        .doc(methodId);
    await ref.delete();
  }

  Future<void> requestPayout({
    required String sellerId,
    required double amount,
    required String methodId,
  }) async {
    final ref =
        FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .collection('payouts')
            .doc();
    final methodDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .collection('payoutMethods')
            .doc(methodId)
            .get();
    final method = methodDoc.data();
    await ref.set({
      'amount': amount,
      'status': 'pending',
      'method': method != null ? method['type'] : '',
      'reference': ref.id,
      'date': DateTime.now().toIso8601String(),
    });
  }
}

// =============================================================================
// GENERIC FIRESTORE REPOSITORY
//
// Every entity repository extends this and only implements fromMap/toMap +
// its collection path. Gives get/create/update/delete/watch for free.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreRepository<T> {
  FirestoreRepository(this.collectionPath, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String collectionPath;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get collection => _db.collection(collectionPath);

  /// Build a model instance from a document id + its field map.
  T fromMap(String id, Map<String, dynamic> map);

  /// Build the field map to write for a model instance.
  Map<String, dynamic> toMap(T item);

  Future<T?> getById(String id) async {
    final doc = await collection.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return fromMap(doc.id, data);
  }

  /// Creates a document. Pass [id] to control the doc id (e.g. the auth
  /// uid for the users collection); otherwise Firestore auto-generates one.
  Future<String> create(T item, {String? id}) async {
    final data = toMap(item);
    if (id != null) {
      await collection.doc(id).set(data);
      return id;
    }
    final ref = await collection.add(data);
    return ref.id;
  }

  Future<void> set(String id, T item) => collection.doc(id).set(toMap(item));

  Future<void> update(String id, Map<String, dynamic> patch) => collection.doc(id).update(patch);

  Future<void> delete(String id) => collection.doc(id).delete();

  /// One-off fetch of all docs belonging to [userId].
  Future<List<T>> fetchByUser(
    String userId, {
    String field = 'user_id',
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> q = collection.where(field, isEqualTo: userId);
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => fromMap(d.id, d.data())).toList();
  }

  /// Realtime stream of docs belonging to [userId] — use for live UI.
  Stream<List<T>> watchByUser(
    String userId, {
    String field = 'user_id',
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> q = collection.where(field, isEqualTo: userId);
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((snap) => snap.docs.map((d) => fromMap(d.id, d.data())).toList());
  }
}

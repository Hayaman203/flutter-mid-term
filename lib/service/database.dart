import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addProductDetails(
      Map<String, dynamic> productInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Product")
        .doc(id)
        .set(productInfoMap);
  }

  Future<Stream<QuerySnapshot>> getProductDetails() async {
    return await FirebaseFirestore.instance.collection("Product").snapshots();
  }

  Future updateProductDetails(
      Map<String, dynamic> updateInfo, String id) async {
    return await FirebaseFirestore.instance
        .collection("Product")
        .doc(id)
        .update(updateInfo);
  }

  Future deleteProductDetails(String id) async {
    return await FirebaseFirestore.instance
        .collection("Product")
        .doc(id)
        .delete();
  }
}

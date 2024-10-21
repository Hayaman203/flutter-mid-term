import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:random_string/random_string.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: 'AIzaSyAmCc5423Q83Y1wgMkvf4AagTHzWtBleWc',
    appId: '1:1012393034241:android:1dc38d06ac35ae90637600',
    messagingSenderId: '1012393034241',
    projectId: 'productapp-46b61',
    storageBucket: 'productapp-46b61.appspot.com',
  ));
  runApp(MaterialApp(
    theme: ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
    ),
    home: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Stream? ProductStream;

  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker
  File? _image; // Biến để lưu hình ảnh đã chọn

  getontheload() async {
    ProductStream = await DatabaseMethods().getProductDetails();
    setState(() {});
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  // Hàm chọn ảnh từ thư viện
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Hàm tải ảnh lên Firebase Storage và trả về đường dẫn
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = randomAlphaNumeric(10); // Tạo tên file ngẫu nhiên
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('product_images/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Hàm thêm sản phẩm và tải ảnh lên
  Future<void> addProduct() async {
    if (_image != null) {
      String? imageUrl = await uploadImage(_image!); // Tải ảnh và nhận URL
      if (imageUrl != null) {
        String Id = randomAlphaNumeric(10);
        Map<String, dynamic> productInfoMap = {
          "ProductName": namecontroller.text,
          "ProductType": typecontroller.text,
          "ProductPrice": pricecontroller.text,
          "ProductImage": imageUrl, // Lưu URL ảnh vào Firestore
          "ProductId": Id,
        };

        await DatabaseMethods()
            .addProductDetails(productInfoMap, Id)
            .then((value) {
          Fluttertoast.showToast(
              msg: "Product has been added successfully!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        });
      }
    } else {
      Fluttertoast.showToast(
          msg: "Please select an image!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  Widget allProductDetails() {
    return StreamBuilder(
        stream: ProductStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Image(
                                image: AssetImage(
                                  "assets/pant.jpg",
                                ),
                                width: 120,
                                height: 120,
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Tên sp: " + ds["ProductName"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Giá sp: " + ds["ProductPrice"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Loại sp:" + ds["ProductType"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      namecontroller.text = ds["ProductName"];
                                      typecontroller.text = ds["ProductType"];
                                      pricecontroller.text = ds["ProductPrice"];
                                      imagecontroller.text = ds["ProductImage"];
                                      EditProductDetail(ds['ProductId']);
                                    },
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await DatabaseMethods()
                                          .deleteProductDetails(
                                              ds['ProductId']);
                                    },
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  })
              : Container();
        });
  }

  TextEditingController namecontroller = TextEditingController();
  TextEditingController typecontroller = TextEditingController();
  TextEditingController pricecontroller = TextEditingController();
  TextEditingController imagecontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dữ liệu sản phẩm"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: namecontroller,
              decoration: const InputDecoration(
                labelText: "Tên sản phẩm",
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: typecontroller,
              decoration: const InputDecoration(
                labelText: "Loại sản phẩm",
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: pricecontroller,
              decoration: const InputDecoration(
                labelText: "Giá sản phẩm",
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: imagecontroller,
              decoration: const InputDecoration(
                labelText: "Hình ảnh sản phẩm",
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: pickImage,
            child: const Text("Chọn hình ảnh"),
          ),
          _image != null
              ? Image.file(
                  _image!,
                  height: 100,
                  width: 100,
                )
              : Container(),
          TextButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.blue),
            ),
            child: const Text(
              "Thêm sản phẩm",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              print(namecontroller.text);
              String Id = randomAlphaNumeric(10);
              Map<String, dynamic> productInfoMap = {
                "ProductName": namecontroller.text,
                "ProductType": typecontroller.text,
                "ProductPrice": pricecontroller.text,
                "ProductImage": imagecontroller.text,
                "ProductId": Id,
              };

              await DatabaseMethods()
                  .addProductDetails(productInfoMap, Id)
                  .then((value) {
                Fluttertoast.showToast(
                    msg: "Product Details has been uploaded successfully!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0);
              });
            },
          ),
          const SizedBox(
            height: 8.0,
          ),
          const Text(
            "Danh sách sản phẩm:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: allProductDetails())
        ],
      ),
    );
  }

  Future EditProductDetail(String id) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            content: Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.cancel),
                      ),
                      const SizedBox(
                        width: 60,
                      ),
                      const Text(
                        "Edit",
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Details",
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: namecontroller,
                      decoration: const InputDecoration(
                        labelText: "Tên sản phẩm",
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: typecontroller,
                      decoration: const InputDecoration(
                        labelText: "Loại sản phẩm",
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: pricecontroller,
                      decoration: const InputDecoration(
                        labelText: "Giá sản phẩm",
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: imagecontroller,
                      decoration: const InputDecoration(
                        labelText: "Hình ảnh sản phẩm",
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                        onPressed: () async {
                          print(namecontroller.text);
                          Map<String, dynamic> updateInfo = {
                            "ProductName": namecontroller.text,
                            "ProductType": typecontroller.text,
                            "ProductPrice": pricecontroller.text,
                            "ProductImage": imagecontroller.text,
                            "ProductId": id,
                          };

                          await DatabaseMethods()
                              .updateProductDetails(updateInfo, id)
                              .then((value) {
                            Navigator.pop(context);
                          });
                        },
                        child: const Text("Cập nhật")),
                  )
                ],
              ),
            ),
          ));
}

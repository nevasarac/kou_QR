import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';


class esya_ekle extends StatefulWidget {
  const esya_ekle({Key? key}) : super(key: key);

  @override
  State<esya_ekle> createState() => _esya_ekleState();
}

class _esya_ekleState extends State<esya_ekle> {

  Future<void> addDataToFirestore(String esyaAdi, String kullananKisi,
      String zimmetli, DateTime tarih, String imageUrl) async {
    try {
      CollectionReference esyalarCollection =
          FirebaseFirestore.instance.collection('Esyalar');

      DocumentReference docRef = await esyalarCollection.add({
        'Alinan_tarih': tarih,
        'Esya_adi': esyaAdi,
        'Kullanan_kisi': kullananKisi,
        'Zimmetli': zimmetli,
        'resimURL': imageUrl, // Yüklenen fotoğrafın URL'sini ekleyin
      });

    } catch (error) {
      print('Firestore\'a veri eklenirken hata oluştu: $error');
    }
  }


  Future<String> uploadImageToFirebaseStorage(File imageFile) async {
  String fileName = DateTime.now().millisecondsSinceEpoch.toString();
  Reference storageReference = FirebaseStorage.instance.ref().child(fileName);
  UploadTask uploadTask = storageReference.putFile(imageFile);
  TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
  String imageUrl = await storageReference.getDownloadURL();
  return imageUrl;
}


  File? _image;
  Future _getImageFromCamera() async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future _getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
  }

  TextEditingController _esyaAdiController = TextEditingController();
  TextEditingController _kullananKisiController = TextEditingController();
  TextEditingController _zimmetliController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
  appBar: AppBar(
    title: Text('Veri Ekle'),
  ),
  body: Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _image != null
            ? Image.file(
                _image!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              )
            : Text('Fotoğraf seçilmedi'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _getImageFromCamera,
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueGrey,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _getImageFromGallery,
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueGrey,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Icon(Icons.image, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: TextField(
              controller: _esyaAdiController,
              decoration: InputDecoration(
                hintText: "Eşya Adı Girin",
                prefixIcon: Icon(Icons.shopping_bag),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: TextField(
              controller: _kullananKisiController,
              decoration: InputDecoration(
                hintText: "Kullanan Kişi Girin",
                prefixIcon: Icon(Icons.person),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: TextField(
              controller:  _zimmetliController,
              decoration: InputDecoration(
                hintText: "Zimmetli Girin",
                prefixIcon: Icon(Icons.label),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: () => _selectDate(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
            child: Text(
              _selectedDate != null
                  ? 'Seçilen Tarih: ${DateFormat('dd MMM y', 'tr_TR').format(_selectedDate!)}'
                  : 'Tarih Seç',
              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
  onPressed: () async {
    if (_selectedDate != null && _image != null &&
        _esyaAdiController.text.isNotEmpty &&
        _kullananKisiController.text.isNotEmpty &&
        _zimmetliController.text.isNotEmpty) {
      String imageUrl = await uploadImageToFirebaseStorage(_image!);
      await addDataToFirestore(
        _esyaAdiController.text,
        _kullananKisiController.text,
        _zimmetliController.text,
        _selectedDate!,
        imageUrl,
      );
      _esyaAdiController.clear();
      _kullananKisiController.clear();
      _zimmetliController.clear();
      setState(() {
        _selectedDate = null;
        _image = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri eklendi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
    }
  },
  style: ElevatedButton.styleFrom(
    primary: Colors.blueGrey,
    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
  ),
  child: Text(
    'Veriyi Ekle',
    style: TextStyle(fontSize: 18, color: Colors.white),
  ),
),

        ],
      ),
    ),
  ),
);
;



  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kou_karekod/QrSayfasi.dart';
import 'package:kou_karekod/esya_ekle.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class EsyaListesi extends StatefulWidget {
  @override
  _EsyaListesiState createState() => _EsyaListesiState();
}

class _EsyaListesiState extends State<EsyaListesi> {
  QRViewController? _qrViewController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  Future<void> _editItem(String documentName) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentSnapshot documentSnapshot =
          await firestore.collection('Esyalar').doc(documentName).get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> existingData =
            documentSnapshot.data() as Map<String, dynamic>;

        TextEditingController nameController =
            TextEditingController(text: existingData['Esya_adi']);
        TextEditingController kullananController =
            TextEditingController(text: existingData['Kullanan_kisi']);
        TextEditingController zimmetliController =
            TextEditingController(text: existingData['Zimmetli']);

        // Alinan_tarih değerini DateTime türüne çevirme
        Timestamp alinanTarihTimestamp = existingData['Alinan_tarih'];
        DateTime alinanTarihDateTime = alinanTarihTimestamp.toDate();

        // DateTime türündeki alinanTarihDateTime'ı düzenlenebilir bir tarih alanına bağlama
        DateTime selectedDate = alinanTarihDateTime;
        TextEditingController alinanTarihController = TextEditingController(
            text:
                '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year.toString()}');

        // Resim URL'sini al
        String resimURL = existingData['resimURL'];

        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Öğeyi Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      child: Image.network(
                        resimURL,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Eşya Adı'),
                    ),
                    TextFormField(
                      controller: kullananController,
                      decoration: InputDecoration(labelText: 'Kullanıcı Adı'),
                    ),
                    TextFormField(
                      controller: zimmetliController,
                      decoration: InputDecoration(labelText: 'Zimmetli'),
                    ),
                    // Düzenlenebilir tarih alanı
                    TextFormField(
                      controller: alinanTarihController,
                      decoration: InputDecoration(labelText: 'Alınan Tarih'),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );

                        if (pickedDate != null && pickedDate != selectedDate) {
                          selectedDate = pickedDate;
                          alinanTarihController.text =
                              '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year.toString()}';
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    Map<String, dynamic> updatedData = {
                      'Esya_adi': nameController.text,
                      'Kullanan_kisi': kullananController.text,
                      'Zimmetli': zimmetliController.text,
                      'Alinan_tarih': Timestamp.fromDate(selectedDate),
                    };

                    await firestore
                        .collection('Esyalar')
                        .doc(documentName)
                        .update(updatedData);

                    Navigator.of(context).pop();
                  },
                  child: Text('Kaydet'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('İptal'),
                ),
              ],
            );
          },
        );
      } else {
        print('Belirtilen belge bulunamadı.');
      }
    } catch (error) {
      print('Veri çekme hatası: $error');
    }
  }

  void _ListeAc() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Eşya Ekle'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => esya_ekle(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Kamerayı Aç'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KameraScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrViewController = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      // Burada QR kod okunduğunda yapılacak işlemleri gerçekleştirebilirsiniz.
      print('QR Kod Okundu: $scanData');
    });
  }

  @override
  void dispose() {
    _qrViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(0, 156, 69, 1.0),
        title: Text('Eşyalar Listesi'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Esyalar').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          var items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var itemData = items[index].data() as Map<String, dynamic>;
              String documentName = items[index].id; // Döküman ismini alma
              Timestamp timestamp = itemData['Alinan_tarih'];
              DateTime dateTime = timestamp.toDate();

              return ListTile(
                title: Text(itemData['Esya_adi']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Kullanan Kişi: ${itemData['Kullanan_kisi'] ?? "Belirtilmemiş"}'),
                    Text(
                        'Zimmetli Kişi: ${itemData['Zimmetli'] ?? "Belirtilmemiş"}'),
                    Text(
                        'Satın Alınan Tarih: ${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString()}'), // Gün, ay, yıl şeklinde yazdırma
                  ],
                ),
                leading: Container(
                  width: 80, // İstediğiniz genişliği burada ayarlayabilirsiniz
                  height:
                      80, // İstediğiniz yüksekliği burada ayarlayabilirsiniz
                  child: Image.network(
                    itemData['resimURL'],
                    fit: BoxFit.cover, // Resmi sınırlar içine yerleştirir
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit_outlined),
                  onPressed: () {
                    _editItem(
                        documentName); // Düzenleme işlevselliğini başlatan fonksiyon
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ListeAc,
        child: Icon(
          Icons.align_horizontal_right,
          color: Colors.black,
        ),
        backgroundColor: Color.fromRGBO(0, 156, 69, 1.0),
      ),
    );
  }
}

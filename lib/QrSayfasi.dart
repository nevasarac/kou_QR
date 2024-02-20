import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class KameraScreen extends StatefulWidget {
  @override
  _KameraScreenState createState() => _KameraScreenState();
}

class _KameraScreenState extends State<KameraScreen> {
  QRViewController? _qrViewController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kamera'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: CupertinoButton(
              onPressed: () async {
                if (_qrViewController != null) {
                  await _qrViewController!.toggleFlash();
                }
              },
              color: Color.fromRGBO(167, 222, 190, 1.0),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: const Text(
                "Feneri Aç/Kapat",
                style: TextStyle(
                  fontSize: 17,
                  color: Color.fromRGBO(57, 62, 63, 1.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrViewController = controller;
    setState(() {
      _qrViewController = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      // scanData bir Barcode nesnesidir
      if (scanData.format == BarcodeFormat.qrcode) {
        // QR kod türü QR kodsa
        _showQRCodeDialog(scanData.code!);
        controller.pauseCamera();
      } else {
        print('Farklı bir kod türü tespit edildi: ${scanData.format}');
      }
    });
  }

  @override
  void dispose() {
    _qrViewController?.dispose();
    super.dispose();
  }

  void _showQRCodeDialog(String qrCodeData) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              title: Text("Eşya Bilgileri"),
              content: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Esyalar')
                    .where(FieldPath.documentId, isEqualTo: qrCodeData)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (!snapshot.hasData) {
                    return Text('Eşya bulunamadı.1');
                  }

                  var documents = snapshot.data?.docs;
                  if (documents == null || documents.isEmpty) {
                    return Text('Eşya bulunamadı.2');
                  }

                  var firstDocument = documents[0];
                  var esyaAdi = firstDocument['Esya_adi'];
                  var kullanankisi = firstDocument['Kullanan_kisi'];
                  var zimmetlikisi = firstDocument['Zimmetli'];
                  var alinanTarih = firstDocument['Alinan_tarih'];

                  var formattedDate = ""; // Bu değişkeni oluşturacağız.

                  if (alinanTarih != null && alinanTarih is Timestamp) {
                    // alinanTarih Timestamp türünde ise işlemleri gerçekleştir.
                    var dateTime = (alinanTarih as Timestamp).toDate();
                    var day = dateTime.day.toString().padLeft(2, '0');
                    var month = dateTime.month.toString().padLeft(2, '0');
                    var year = dateTime.year.toString();

                    formattedDate = '$day-$month-$year';
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Başlangıç hizalamasını ayarlıyoruz.
                    children: [
                      SizedBox(
                          height:
                              10), // Resim ile metin arasında boşluk bırakıyoruz.
                      firstDocument['resimURL'] != null
                          ? Image.network(
                              firstDocument[
                                  'resimURL'], // Firestore'dan gelen resim URL'si
                              width: 200, // Resim genişliği
                              height: 200, // Resim yüksekliği
                              fit:
                                  BoxFit.cover, // Resmin nasıl yerleştirileceği
                            )
                          : Container(),

                      SizedBox(
                          height: 5), // Üst tarafta biraz boşluk bırakıyoruz.
                      Text(
                        'Eşya Adı: $esyaAdi',
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 5),

                      Text(
                        'Kullanan Kişi: $kullanankisi',
                        style: TextStyle(fontSize: 17),
                      ),
                      SizedBox(
                          height: 5), // Metinler arasında boşluk bırakıyoruz.

                      Text(
                        'Zimmetli Kişi: $zimmetlikisi',
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 5),

                      Text(
                        'Alınan Tarih: $formattedDate',
                        style: TextStyle(fontSize: 17),
                      ),
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _qrViewController!.resumeCamera();
                  },
                  child: Text('Tamam'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kou_karekod/esya_listesi.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromRGBO(18, 14, 67, 0.004)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Kocaeli Üniversitesi'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> _login() async {
    print('1');
    final url = Uri.parse('http://185.92.2.229:7171/login');
    final data = {
      'username': usernameController.text,
      'password': passwordController.text,
    };
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EsyaListesi()),
      );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Başarılı giriş durumunu işleyin
      Map<String, dynamic> responseBody = jsonDecode(response.body);

      // JSON'dan çıkan verileri kullanabilirsiniz
      String userId = responseBody['userId'];
      String token = responseBody['token'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EsyaListesi()),
      );
    } else {
      // Hatalı giriş durumunu işleyin
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Giriş Yapılamadı'),
            content: Text('Kullanıcı adı veya şifre yanlış.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Tamam'),
              ),
            ],
          );
        },
      );
    }
    print(response.statusCode);
  }

  @override
  Widget build(BuildContext context) {
    var ekranbilgisi = MediaQuery.of(context);
    final double ekranyukseklik = ekranbilgisi.size.height;
    final double ekrangenislik = ekranbilgisi.size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Okul logosu
              Image.asset(
                'resimler/yesil.jpg',
                fit: BoxFit.fitWidth,
                width: ekrangenislik,
                height: null,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                child: TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                      hintText: "Kullanıcı Adı",
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                        color: Colors.grey,
                      ))),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                child: TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                      hintText: "Şifre",
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                        color: Colors.grey,
                      ))),
                ),
              ),
              SizedBox(height: 20),
              CupertinoButton(
                onPressed: _login,
                color: Color.fromRGBO(167, 222, 190, 1.0),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                child: const Text(
                  "Giriş yap",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromRGBO(57, 62, 63, 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

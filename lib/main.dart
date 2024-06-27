import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('혈압 입력'),
        ),
        body: BloodPressureForm(),
      ),
    );
  }
}

class BloodPressureForm extends StatefulWidget {
  @override
  _BloodPressureFormState createState() => _BloodPressureFormState();
}

class _BloodPressureFormState extends State<BloodPressureForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _maxPressureController = TextEditingController();
  final TextEditingController _minPressureController = TextEditingController();

  void _saveDataAndNavigate(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      // Firestore 인스턴스 생성
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 데이터 저장
      DocumentReference docRef =
          await firestore.collection('bloodPressureRecords').add({
        'maxPressure': _maxPressureController.text,
        'minPressure': _minPressureController.text,
        'timestamp': FieldValue.serverTimestamp(), // 시간 기록
      });

      // 다음 페이지로 이동하며 문서 ID 전달
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryScreen(documentId: docRef.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextFormField(
            controller: _maxPressureController,
            decoration: InputDecoration(labelText: '최고 혈압'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '최고 혈압을 입력하세요';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _minPressureController,
            decoration: InputDecoration(labelText: '최저 혈압'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '최저 혈압을 입력하세요';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: () => _saveDataAndNavigate(context),
            child: Text('전송'),
          ),
        ],
      ),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  final String documentId;

  SummaryScreen({required this.documentId});

  Future<Map<String, dynamic>> _fetchData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot docSnapshot = await firestore
        .collection('bloodPressureRecords')
        .doc(documentId)
        .get();
    return docSnapshot.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("혈압 요약"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No data found'));
          } else {
            final data = snapshot.data!;
            final maxPressure = data['maxPressure'];
            final minPressure = data['minPressure'];
            return Center(
              child: Text('최고 혈압: $maxPressure, 최저 혈압: $minPressure'),
            );
          }
        },
      ),
    );
  }
}

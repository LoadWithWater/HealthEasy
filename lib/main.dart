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
      title: 'Phone Number Input',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    // 휴대폰 번호 형식 검사 (예: 한국 휴대폰 번호 형식 검사)
    String pattern = r'^(010|011|016|017|018|019)\d{7,8}$';
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return '휴대폰 번호를 입력해 주세요.';
    } else if (!regex.hasMatch(value)) {
      return '유효한 휴대폰 번호를 입력해 주세요.';
    }
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // 유효한 경우 메인 메뉴로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainMenu()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('휴대폰 번호 입력'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // 폼의 상태를 추적하는 글로벌 키
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _phoneController, // 컨트롤러로 텍스트를 관리
                decoration: InputDecoration(
                  labelText: '휴대폰 번호',
                  hintText: '예: 01012345678',
                ),
                keyboardType: TextInputType.phone, // 키보드 타입을 전화번호로 설정
                validator: _validatePhoneNumber, // 유효성 검사 함수
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm, // 폼 제출 함수 호출
                child: Text('제출'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('메인 메뉴'),
      ),
      body: PageView(
        children: <Widget>[
          _buildMenuPage(context, '건강 데이터 수집', BloodPressureForm()),
          _buildMenuPage(context, '건강 모니터링', MonitoringPage()),
          _buildMenuPage(context, '비대면 진료', TelemedicinePage()),
        ],
      ),
    );
  }

  Widget _buildMenuPage(BuildContext context, String title, Widget page) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(title),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('혈압 입력'),
      ),
      body: Form(
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
      ),
    );
  }
}

class SummaryScreen extends StatefulWidget {
  final String documentId;

  SummaryScreen({required this.documentId});

  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String? maxPressure;
  String? minPressure;

  Future<void> _fetchData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot docSnapshot = await firestore
        .collection('bloodPressureRecords')
        .doc(widget.documentId)
        .get();
    final data = docSnapshot.data() as Map<String, dynamic>;
    setState(() {
      maxPressure = data['maxPressure'];
      minPressure = data['minPressure'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("혈압 요약"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _fetchData,
              child: Text('혈압 값 조회'),
            ),
            if (maxPressure != null && minPressure != null)
              Text('최고 혈압: $maxPressure, 최저 혈압: $minPressure'),
          ],
        ),
      ),
    );
  }
}

class MonitoringPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('건강 모니터링'),
      ),
      body: Center(
        child: Text('건강 모니터링 페이지 내용'),
      ),
    );
  }
}

class TelemedicinePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('비대면 진료'),
      ),
      body: Center(
        child: Text('비대면 진료 페이지 내용'),
      ),
    );
  }
}

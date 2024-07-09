import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(MyApp());
  } catch (e) {
    runApp(ErrorApp(Exception(e.toString())));
  }
}

class ErrorApp extends StatelessWidget {
  final Exception error;

  ErrorApp(this.error);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error',
      home: Scaffold(
        body: Center(
          child: Text('앱 초기화에 실패했습니다: ${error.toString()}'),
        ),
      ),
    );
  }
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    String pattern = r'^(010|011|016|017|018|019)\d{7,8}$';
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return '휴대폰 번호를 입력해 주세요.';
    } else if (!regex.hasMatch(value)) {
      return '유효한 휴대폰 번호를 입력해 주세요.';
    }
    return null;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+82${_phoneController.text.substring(1)}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MainMenu()),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('인증에 실패했습니다: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
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
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '휴대폰 번호',
                  hintText: '예: 01012345678',
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhoneNumber,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('제출'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OTPVerificationPage extends StatefulWidget {
  final String verificationId;

  OTPVerificationPage({required this.verificationId});

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOTP() async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text,
      );
      await _auth.signInWithCredential(credential);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainMenu()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP 인증에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP 인증'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'OTP 코드',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOTP,
              child: Text('인증'),
            ),
          ],
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
          _buildMenuPage(context, '건강 정보 입력', BasicDataPage()),
          _buildMenuPage(context, '건강 정보 측정', MeasureingPage()),
          _buildMenuPage(context, '건강 정보 모니터링', MonitoringPage()),
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

class BasicDataPage extends StatefulWidget {
  @override
  _BasicDataFormState createState() => _BasicDataFormState();
}

class _BasicDataFormState extends State<BasicDataPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveDataAndNavigate(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        DocumentReference docRef =
            await _firestore.collection('BasicHealthDataRecords').add({
          'age': _ageController.text,
          'gender': _genderController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SummaryScreen1(documentId1: docRef.id),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 저장에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('기본 건강 정보 입력'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(labelText: '나이'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '나이를 입력하세요';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _genderController,
              decoration: InputDecoration(labelText: '성별'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '성별을 입력하세요';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _heightController,
              decoration: InputDecoration(labelText: '키'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '키를 입력하세요';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(labelText: '체중'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '체중을 입력하세요';
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

class SummaryScreen1 extends StatefulWidget {
  final String documentId1;

  SummaryScreen1({required this.documentId1});

  @override
  _SummaryScreenState1 createState() => _SummaryScreenState1();
}

class _SummaryScreenState1 extends State<SummaryScreen1> {
  String? age;
  String? gender;
  String? height;
  String? weight;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _fetchData() async {
    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection('BasicHealthDataRecords')
          .doc(widget.documentId1)
          .get();
      final data = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        age = data['age'];
        gender = data['gender'];
        height = data['height'];
        weight = data['weight'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 불러오기에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("기본 건강 정보 요약"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _fetchData,
              child: Text('기본 건강 정보 조회'),
            ),
            if (age != null &&
                gender != null &&
                height != null &&
                weight != null)
              Text('나이: $age\n성별: $gender\n키: $height\n체중: $weight'),
          ],
        ),
      ),
    );
  }
}

class MeasureingPage extends StatefulWidget {
  @override
  _BloodPressureFormState createState() => _BloodPressureFormState();
}

class _BloodPressureFormState extends State<MeasureingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _maxPressureController = TextEditingController();
  final TextEditingController _minPressureController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveDataAndNavigate(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        DocumentReference docRef =
            await _firestore.collection('bloodPressureRecords').add({
          'maxPressure': _maxPressureController.text,
          'minPressure': _minPressureController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SummaryScreen2(documentId2: docRef.id),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 저장에 실패했습니다: $e')),
        );
      }
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

class SummaryScreen2 extends StatefulWidget {
  final String documentId2;

  SummaryScreen2({required this.documentId2});

  @override
  _SummaryScreenState2 createState() => _SummaryScreenState2();
}

class _SummaryScreenState2 extends State<SummaryScreen2> {
  String? maxPressure;
  String? minPressure;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _fetchData() async {
    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection('bloodPressureRecords')
          .doc(widget.documentId2)
          .get();
      final data = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        maxPressure = data['maxPressure'];
        minPressure = data['minPressure'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 불러오기에 실패했습니다: $e')),
      );
    }
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
        title: Text('건강 정보 모니터링'),
      ),
      body: Center(
        child: Text('건강 정보 모니터링 페이지 내용'),
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

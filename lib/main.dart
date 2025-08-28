import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'providers/contact_provider.dart';
import 'providers/sms_provider.dart';
import 'providers/sender_filter_provider.dart';
import 'providers/group_provider.dart';
import 'services/sms_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => SmsProvider()),
        ChangeNotifierProvider(create: (_) => SenderFilterProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: MaterialApp(
        title: 'SMS Forwarder',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final smsProvider = Provider.of<SmsProvider>(context, listen: false);
    final senderFilterProvider = Provider.of<SenderFilterProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    // Initialize SMS service
    SmsService.initialize(
      smsProvider: smsProvider,
      senderFilterProvider: senderFilterProvider,
      groupProvider: groupProvider,
    );

    // Check and request permissions on app start
    await _checkAndRequestPermissions();

    // Load initial data
    await Future.wait([
      contactProvider.loadContacts(),
      smsProvider.loadSmsLogs(limit: 100),
      senderFilterProvider.loadSenderFilters(),
      groupProvider.loadGroups(),
    ]);
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      // First check if permissions are already granted
      final hasPermissions = await SmsService.checkPermissions();
      
      if (!hasPermissions) {
        // Show a dialog explaining why permissions are needed
        if (mounted) {
          final shouldRequest = await _showPermissionDialog();
          if (shouldRequest) {
            // Request permissions
            await SmsService.requestPermissions();
            
            // Check again after request
            final permissionsGranted = await SmsService.checkPermissions();
            if (!permissionsGranted && mounted) {
              _showPermissionDeniedDialog();
            }
          }
        }
      }
    } catch (e) {
      print('Error during permission check: $e');
    }
  }

  Future<bool> _showPermissionDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('권한 필요'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SMS Forwarder가 정상적으로 작동하려면 다음 권한이 필요합니다:'),
              SizedBox(height: 10),
              Text('• SMS 수신 권한'),
              Text('• SMS 전송 권한'), 
              Text('• SMS 읽기 권한'),
              SizedBox(height: 10),
              Text('이 권한들은 SMS를 자동으로 전달하는 기능에 꼭 필요합니다.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('나중에'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('권한 허용'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('권한 거부됨'),
          content: Text('SMS 권한이 거부되어 앱의 핵심 기능을 사용할 수 없습니다. 설정에서 권한을 수동으로 허용할 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('닫기'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                SmsService.openAppSettings();
              },
              child: Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen();
  }
}

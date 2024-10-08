import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('com.example.flutter_callkit_incoming');

  final Uuid uuid = Uuid();
  String textEvents = "";
  final AudioPlayer _audioPlayer = AudioPlayer();

  late final Uuid _uuid;
  String? _currentUuid;

  @override
  void initState() {
    super.initState();
    //initCallKit();
    platform.setMethodCallHandler(_handleMethod);
    listenerEvent(onEvent);
  }

  Future<dynamic> initCurrentCall() async {
    //await requestNotificationPermission();
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA: $calls');
        _currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        _currentUuid = "";
        return null;
      }
    }
  }

  Future<void> checkActiveCallAndHandle() async {

    var activeCallsRaw = await FlutterCallkitIncoming.activeCalls();

    // 型キャストを行って、List<Map<String, dynamic>>に変換
    List<Map<String, dynamic>> activeCalls = [];

    for (var call in activeCallsRaw) {
      if (call is Map<String, dynamic>) {
        activeCalls.add(call);
      } else if (call is Map) {
        activeCalls.add(Map<String, dynamic>.from(call));
      }
    }
    if (activeCalls.isNotEmpty) {
      print("There is an active call");
      // アクティブな通話がある場合の処理
      handleActiveCall(activeCalls);
    } else {
      print("No active calls");
      // アクティブな通話がない場合の処理
    }
  }

  void handleActiveCall(List<Map<String, dynamic>> activeCalls) async {

    await Future.delayed(Duration(seconds: 1));
    for (var call in activeCalls) {
      print("----------------------------");
      print("Active call: ${call['id']}");
      print(activeCalls[0]['id']);
      print(call);
      print("----------------------------");
      //print(call);
      // ここで通話の詳細を取得し、必要に応じて処理を行う
    }

  }

  void onEvent(CallEvent event) {
    if (!mounted) return;
    setState(() {
      //textEvents += '---\n${event.toString()}\n';
      textEvents += '---\n${event.event!}\n';
    });
  }

  Future<void> _playAudio() async {
    // オーディオを再生
    await _audioPlayer.play(UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
  }

  Future<void> listenerEvent(void Function(CallEvent) callback) async {
    try {
      FlutterCallkitIncoming.onEvent.listen((event) async {
        print('HOME: $event');
        print("=======================");
        print(event!.event);
        print("=======================");
        switch (event!.event) {
          case Event.actionCallIncoming:
          // TODO: received an incoming call
            break;
          case Event.actionCallStart:
          // TODO: started an outgoing call
          // TODO: show screen calling in Flutter
            break;
          case Event.actionCallAccept:
            await checkActiveCallAndHandle(); // 通話のアクティブ状態をチェックして処理
          // TODO: accepted an incoming call
          // TODO: show screen calling in Flutter
          //NavigationService.instance
          //    .pushNamedIfNotCurrent(AppRoute.callingPage, args: event.body);
            _playAudio();
            break;
          case Event.actionCallDecline:
            await checkActiveCallAndHandle(); // 通話のアクティブ状態をチェックして処理
          // TODO: declined an incoming call
          //await requestHttp("ACTION_CALL_DECLINE_FROM_DART");
            break;
          case Event.actionCallEnded:
          // TODO: ended an incoming/outgoing call
            print("Call ended");
            //await checkActiveCallAndHandle();
            break;
          case Event.actionCallTimeout:
          // TODO: missed an incoming call
            break;
          case Event.actionCallCallback:
          // TODO: only Android - click action `Call back` from missed call notification
            break;
          case Event.actionCallToggleHold:
          // TODO: only iOS
            break;
          case Event.actionCallToggleMute:
          // TODO: only iOS
            break;
          case Event.actionCallToggleDmtf:
          // TODO: only iOS
            break;
          case Event.actionCallToggleGroup:
          // TODO: only iOS
            break;
          case Event.actionCallToggleAudioSession:
          // TODO: only iOS
            break;
          case Event.actionDidUpdateDevicePushTokenVoip:
          // TODO: only iOS
            break;
          case Event.actionCallCustom:
            break;
        }
        callback(event);
      });
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'showIncomingCall':
        _showIncomingCall(call.arguments);
        break;
      case 'setCurrentUuid':
        _setCurrentUuid(call.arguments);
        break;
    }
  }

  Future<void> _showIncomingCall(Map<dynamic, dynamic> arguments) async {
    print("_showIncomingCall =====");
    await Future.delayed(const Duration(milliseconds: 100), () async {
      final String callId = uuid.v4(); // UUIDを生成

      CallKitParams callKitParams = CallKitParams(
        id: callId,
        nameCaller: 'Hien Nguyen',
        appName: 'Callkit',
        //avatar: 'https://i.pravatar.cc/100',
        avatar: 'https://equal-love.jp/image/profile/otani_emiri.jpg',
        handle: '0123456789',
        type: 0,
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Missed call',
          callbackText: 'Call back',
        ),
        duration: 30000,
        extra: <String, dynamic>{'userId': '1a2b3c4d'},
        headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
        android: const AndroidParams(
            isCustomNotification: true,
            isShowLogo: false,
            ringtonePath: 'system_ringtone_default',
            backgroundColor: '#0955fa',
            backgroundUrl: 'https://i.pravatar.cc/500',
            actionColor: '#4CAF50',
            textColor: '#ffffff',
            incomingCallNotificationChannelName: "Incoming Call",
            missedCallNotificationChannelName: "Missed Call",
            isShowCallID: false
        ),
        ios: IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      //await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
      try {
        await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
      } catch (e) {
        print('Error showing incoming call: $e');
      }
    });
  }

  Future<void> _setCurrentUuid(Map<dynamic, dynamic> arguments) async {
    print("arguments --------");
    print(arguments);
    try {
      _currentUuid = arguments['uuid'];
      showIncomingCallDialog(context, _currentUuid!);
    } catch (e) {
      print('Error showing incoming call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CallKit Example"),

        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              setState(() {
                textEvents = "";
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              try {
                await platform.invokeMethod('endCall', {'uuid': _currentUuid!}); // uuidを渡す
              } catch (e) {
                print("Failed to end call: $e");
              }
            },
          ),
        ],
      ),
      body:
        LayoutBuilder(
          builder:
              (BuildContext context, BoxConstraints viewportConstraints) {
            if (textEvents.isNotEmpty) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: Text(textEvents),
                ),
              );
            } else {
              return const Center(
                child: Text('No Event'),
              );
            }
          },
        ),

      /*Center(
        child:
          Column(
            children: [
              Text("Waiting for a call..."),
              const SizedBox(height: 20,),
              Text(textEvents)
            ],
          )
        //Text("Waiting for a call..."),
      ),*/
    );
  }

  void showIncomingCallDialog(BuildContext context, String uuid) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // 内容を中央に配置
              children: [
                Text(_currentUuid ?? ''),
                SizedBox(height: 40,),
                ElevatedButton(
                  onPressed: () async {
                    print("pressed!");
                    try {
                      await platform.invokeMethod('endCall', {'uuid': _currentUuid!}); // uuidを渡す
                    } catch (e) {
                      print("Failed to end call: $e");
                    }

                    Navigator.of(context).pop();
                    // 通話を終了する処理など
                  },
                  child: Text("End Call"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/*
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
*/
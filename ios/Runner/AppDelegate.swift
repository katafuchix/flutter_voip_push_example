import UIKit
import AVFAudio
import Flutter
import PushKit
import CallKit
import flutter_callkit_incoming

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var callKitProvider: CXProvider?
    var callUUID: UUID?
    var callController: CXCallController!
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    GeneratedPluginRegistrant.register(with: self)
      
      // VOIP通知のためのPushKitのセットアップ
      setupPushKit()
      setupCallKitProvider()
      setupChannel()
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  private func setupPushKit() {
      // Create a push registry object
      let mainQueue = DispatchQueue.main
      let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
      voipRegistry.delegate = self
      voipRegistry.desiredPushTypes = [PKPushType.voIP]
  }

    private func handleVoIPNotification(payload: [AnyHashable: Any]) {
        if let flutterViewController = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "com.example.flutter_callkit_incoming", binaryMessenger: flutterViewController.binaryMessenger)
            
            channel.invokeMethod("showIncomingCall", arguments: [
                "id": "call_id",
                "nameCaller": "Caller Name",
                "handle": "Caller Handle",
                "type": 0, // 0 = Audio Call, 1 = Video Call
                "duration": 30000, // in milliseconds
                "textAccept": "Accept",
                "textDecline": "Decline",
                "textMissedCall": "Missed call",
                "textCallback": "Call back",
                "extra": ["userId": "user_id"],
                "ios": [
                    "iconName": "CallKitLogo",
                    "handleType": "generic",
                    "supportsVideo": true,
                ]
            ])
        }
    }
    
    
    // アプリがバックグラウンドから復帰した際に必要な処理
    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        // 必要に応じてオーディオセッションを再アクティブ化
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to reactivate audio session: \(error)")
        }
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        // 必要な場合、バックグラウンドに移行する前にセッションを無効化
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

//MARK: - PKPushRegistryDelegate
extension AppDelegate : PKPushRegistryDelegate {
    
    // Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print("pushRegistry -> deviceToken :\(deviceToken)")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
    }
        
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType:")
    }
    
    // Handle incoming pushes
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print(payload.dictionaryPayload)
        let payloadDict = payload.dictionaryPayload["aps"] as? [String:Any] ?? [:]
        print(payloadDict);

        
        // 通知から通話ハンドル情報を取得
        //guard let handle = payload.dictionaryPayload["handle"] as? String else { return }
        let handle = "handle"
        // CallKitの設定
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        callUUID = UUID()

        if UIApplication.shared.applicationState == .active {
            print("フォアグラウンドでの処理")
            // フォアグラウンドでの処理
            handleIncomingCallInForeground(callUpdate: callUpdate, completion: completion)
        } else {
            print("バックグラウンドまたはターミネートでの処理")
            // ターミネート状態からの起動時の処理
            //handleIncomingCallInTerminatedState(callUpdate: callUpdate, completion: completion)
            reportIncomingCall(uuid: callUUID!, handle: handle, completion: completion)
        }

    }

    func startAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to start audio session: \(error.localizedDescription)")
        }
    }

    private func establishConnection(for callUUID: UUID) {
        // 通話の確立処理をここに実装します
        print("Establishing connection for call UUID: \(callUUID.uuidString)")
    }
    

    private func handleIncomingCallInForeground(callUpdate: CXCallUpdate, completion: @escaping () -> Void) {
        if let flutterViewController = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "com.example.flutter_callkit_incoming", binaryMessenger: flutterViewController.binaryMessenger)

            channel.invokeMethod("showIncomingCall", arguments: [
                "callerId": "12345",
                "callerName": "John Doe",
                "callerAvatar": "https://example.com/avatar.jpg"
            ])
        }
        completion()
    }

    private func handleIncomingCallInTerminatedState(callUpdate: CXCallUpdate, completion: @escaping () -> Void) {
        
        print("handleIncomingCallInTerminatedState")
        
        callKitProvider?.reportNewIncomingCall(with: callUUID!, update: callUpdate) { error in
            if let error = error {
                print("Failed to report incoming call: \(error.localizedDescription)")
            } else {
                print("Call successfully reported from terminated state")
            }
            // ここで必要な処理を行う（Flutterの初期化待ちなど）
            if let flutterViewController = self.window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(name: "com.example.flutter_callkit_incoming", binaryMessenger: flutterViewController.binaryMessenger)
                
                let arguments: [String: Any] = [
                    "id": self.callUUID!.uuidString,
                    "nameCaller": "Caller Name",
                    "handle": "callUpdate.remoteHandle.value",
                    "type": 0, // 0 = Audio Call, 1 = Video Call
                    "duration": 30000, // in milliseconds
                    "textAccept": "Accept",
                    "textDecline": "Decline",
                    "textMissedCall": "Missed call",
                    "textCallback": "Call back",
                    "extra": ["userId": "user_id"],
                    "ios": [
                        "iconName": "CallKitLogo",
                        "handleType": "generic",
                        "supportsVideo": true,
                    ]
                ]
                
                channel.invokeMethod("showIncomingCall", arguments: arguments)
            }
            completion()
        }
    }
}

extension AppDelegate: CXProviderDelegate {
    // バックグラウンドまたはターミネート時の処理
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: @escaping () -> Void) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = hasVideo

        callKitProvider!.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                // 通話が正常に報告されたので、オーディオセッションを開始
                self.startAudioSession()
            } else {
                // エラー処理
                print("Error reporting incoming call: \(String(describing: error))")
            }
        }
    }

    // 初期化処理
    private func setupCallKitProvider() {
        callController = CXCallController()
        
        let configuration = CXProviderConfiguration(localizedName: "Your App Name")
        configuration.supportsVideo = true
        configuration.maximumCallsPerCallGroup = 1
        configuration.maximumCallGroups = 1
        configuration.supportedHandleTypes = [.generic]

        callKitProvider = CXProvider(configuration: configuration)
        callKitProvider?.setDelegate(self, queue: nil)
        setupChannel()
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("didReset");
    }
    
    // CallKitのデリゲートメソッド
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // 通話を開始する処理を追加
        action.fulfill()
        print("Answer button is pressed")
        print(action.uuid.uuidString)
        print(action.callUUID.uuidString)
        
        if let flutterViewController = self.window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "com.example.flutter_callkit_incoming", binaryMessenger: flutterViewController.binaryMessenger)
            print("flutterViewController")
            print(flutterViewController)
            let arguments: [String: Any] = ["uuid": action.callUUID.uuidString]
            channel.invokeMethod("setCurrentUuid", arguments: arguments)
        }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // 通話を終了する処理を追加
        action.fulfill()
        print("Calling is ended")
    }

    // 通話を終了
    func endCall(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callController.request(transaction) { error in
            if let error = error {
                print("Error ending call: \(error.localizedDescription)")
            } else {
                print("Call ended successfully")
            }
        }
    }

      // Flutter側からの処理を行うための設定
      private func setupChannel() {
          let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
          let channel = FlutterMethodChannel(name: "com.example.flutter_callkit_incoming", binaryMessenger: controller.binaryMessenger)

          channel.setMethodCallHandler({
              (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
              // メソッド名によって処理を分岐
              if call.method == "endCall" {
                  if let args = call.arguments as? [String: String],
                     let uuidString = args["uuid"],
                     let uuid = UUID(uuidString: uuidString) {
                      self.endCall(uuid: uuid)
                      result("Call Ended") // 結果を返す
                  } else {
                      result(FlutterError(code: "INVALID_ARGUMENT", message: "UUID not provided", details: nil))
                  }
              } else {
                  result(FlutterMethodNotImplemented)
              }
          })
      }
}

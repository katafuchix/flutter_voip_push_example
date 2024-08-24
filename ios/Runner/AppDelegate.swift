import UIKit
import Flutter
import PushKit
import CallKit
import flutter_callkit_incoming

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var callKitProvider: CXProvider?
    var callUUID: UUID?
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    GeneratedPluginRegistrant.register(with: self)
      
      // VOIP通知のためのPushKitのセットアップ
      setupPushKit()
      setupCallKitProvider()
      
      // アプリがバックグラウンドから復帰したときの処理
       //if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
       //    handleVoIPNotification(payload: notification)
       //}
      
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
        
        print("didReceiveIncomingPushWith");
        print("UIApplication.shared.applicationState");
        print(UIApplication.shared.applicationState);
        print(UIApplication.shared.applicationState == .active)
        
         print(payload.dictionaryPayload)
        let payloadDict = payload.dictionaryPayload["aps"] as? [String:Any] ?? [:]
        print(payloadDict);

        /*
        let id = payload.dictionaryPayload["id"] as? String ?? ""
        let nameCaller = payload.dictionaryPayload["nameCaller"] as? String ?? ""
        let handle = payload.dictionaryPayload["handle"] as? String ?? ""
        let isVideo = payload.dictionaryPayload["isVideo"] as? Bool ?? false
        
        let data = flutter_callkit_incoming.Data(id: id, nameCaller: nameCaller, handle: handle, type: isVideo ? 1 : 0)
        //set more data
        data.extra = ["user": "abc@123", "platform": "ios"]
        //data.iconName = ...
        //data.....
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
        */
        /*
        var info = [String: Any?]()
        info["uuid"] = "44d915e1-5ff4-4bed-bf13-c423048ec97a"
         info["id"] = "44d915e1-5ff4-4bed-bf13-c423048ec97a"
         info["nameCaller"] = "Hien Nguyen"
         info["handle"] = "0123456789"
         info["type"] = 1
         //... set more data
         SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(flutter_callkit_incoming.Data(args: info), fromPushKit: true)

        
        //Make sure call completion()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion()
        }
        */
        
       /*
        if let flutterViewController = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "com.example.flutter_callkit_incoming", binaryMessenger: flutterViewController.binaryMessenger)

            channel.invokeMethod("showIncomingCall", arguments: [
                "callerId": "12345",
                "callerName": "John Doe",
                "callerAvatar": "https://example.com/avatar.jpg"
            ])
        }
*/
        
        // 通知から通話ハンドル情報を取得
        //guard let handle = payload.dictionaryPayload["handle"] as? String else { return }
        let handle = "handle"
        // CallKitの設定
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        callUUID = UUID()

        if UIApplication.shared.applicationState == .active {
            print("フォアグラウンドまたはバックグラウンドでの処理")
            // フォアグラウンドまたはバックグラウンドでの処理
            handleIncomingCallInForeground(callUpdate: callUpdate, completion: completion)
        } else {
            // ターミネート状態からの起動時の処理
            handleIncomingCallInTerminatedState(callUpdate: callUpdate, completion: completion)
        }
        
        
        /*
        // VoIP通知でない場合は何もしない
        if type != .voIP { return }
        
        // 通知から通話ハンドル情報を取得
        //guard let handle = payload.dictionaryPayload["handle"] as? String else { return }
        let handle = "handle"
        // CallKitの設定
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        let callUUID = UUID()
        
        // 1. CallKitで着信を報告
        callKitProvider?.reportNewIncomingCall(with: callUUID, update: callUpdate) { error in
            if let error = error {
                print("Failed to report incoming call: \(error.localizedDescription)")
                completion()
                return
            }
            
            // 2. 着信が報告された後、pushRegistryのcompletionを呼び出す
            completion()
            
            // 3. Flutterの処理を実行する
            if let flutterViewController = self.window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(name: "com.example.flutter_callkit_incoming", binaryMessenger: flutterViewController.binaryMessenger)
                
                let arguments: [String: Any] = [
                    "id": callUUID.uuidString,
                    "nameCaller": "Caller Name",
                    "handle": handle,
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
        }

        // 通話を確立するためのカスタム処理
        //establishConnection(for: callUUID)
         */

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
        
        /*callKitProvider?.reportNewIncomingCall(with: callUUID!, update: callUpdate) { error in
            if let error = error {
                print("Failed to report incoming call: \(error.localizedDescription)")
            } else {
                print("Call successfully reported in foreground/background")
            }
            completion()
        }*/
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
    
    private func setupCallKitProvider() {
        let configuration = CXProviderConfiguration(localizedName: "Your App Name")
        configuration.supportsVideo = true
        configuration.maximumCallsPerCallGroup = 1
        configuration.maximumCallGroups = 1
        configuration.supportedHandleTypes = [.generic]

        callKitProvider = CXProvider(configuration: configuration)
        callKitProvider?.setDelegate(self, queue: nil)
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("didReset");
    }
    
    // CallKitのデリゲートメソッド
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // 通話を開始する処理を追加
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // 通話を終了する処理を追加
        action.fulfill()
    }
}

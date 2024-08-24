# flutter_voip_push_example

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# flutter_voip_push_example

## Send Test APNs Push Notifications Online
- https://apnspush.com/

## VoIP Push Notification Command

```
% curl --http2 -E hi-chat_voip_services.pem  --header "apns-topic: hi-chat.deskplate.net.voip" -d "{\"message\":\"Hello\", \"alert\":\"Hello\", \"aps\": {\"message\":\"Hello\", \"content-available\":1} }" https://api.development.push.apple.com/3/device/[VoIP Token]
```

## info.plist

```
	<key>UIBackgroundModes</key>
	<array>
		<string>audio</string>
		<string>fetch</string>
		<string>processing</string>
		<string>remote-notification</string>
		<string>voip</string>
	</array>

```


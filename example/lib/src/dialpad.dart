import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mct_calling_app/src/callhistory.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

import 'widgets/action_button.dart';

class DialPadWidget extends StatefulWidget {
  final SIPUAHelper? _helper;

  DialPadWidget(this._helper, {Key? key}) : super(key: key);

  @override
  State<DialPadWidget> createState() => _MyDialPadWidget();
}

class _MyDialPadWidget extends State<DialPadWidget>
    implements SipUaHelperListener {
  String? _dest;
  String? _username;
  SIPUAHelper? get helper => widget._helper;
  TextEditingController? _textController;
  late SharedPreferences _preferences;

  String? receivedMsg;

  @override
  initState() {
    super.initState();
    receivedMsg = "";
    _bindEventListeners();
    _loadSettings();
  }

  void _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();
    _dest = _preferences.getString('dest') ?? '';
    _textController = TextEditingController(text: _dest);
    _textController!.text = _dest!;
    _username = _preferences.getString('username') ?? '';

    setState(() {});
  }

  void _bindEventListeners() {
    helper!.addSipUaHelperListener(this);
  }

  void _logCall(String type, String info) async {
    final List<String> logs = _preferences.getStringList('callLogs') ?? [];
    DateTime now = DateTime.now();
    String entry = jsonEncode(
        {'type': type, 'info': info, 'timestamp': now.toIso8601String()});
    logs.insert(0, entry);
    await _preferences.setStringList('callLogs', logs);
  }

  Future<Widget?> _handleCall(BuildContext context,
      [bool voiceOnly = false]) async {
    final dest = _textController?.text;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        kIsWeb) {
      print('awaiting access');
      await Permission.microphone.request();
      // await Permission.camera.request();
    }
    if (dest == null || dest.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Target is empty.'),
            content: Text('Please enter a SIP URI or username!'),
            actions: <Widget>[
              TextButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return null;
    }
    _logCall('Outgoing', '$dest'); // Log outgoing call
    print('Dialing: $dest');

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': voiceOnly
          ? false
          : {
              'width': 1280,
              'height': 720,
              'facingMode': 'user',
            },
    };

    MediaStream mediaStream;

    try {
      if (kIsWeb && !voiceOnly) {
        mediaStream =
            await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
        mediaConstraints['video'] = false;
        MediaStream userStream =
            await navigator.mediaDevices.getUserMedia(mediaConstraints);
        final audioTracks = userStream.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          mediaStream.addTrack(audioTracks.first, addToNative: true);
        }
      } else {
        mediaStream =
            await navigator.mediaDevices.getUserMedia(mediaConstraints);
      }
      print('Media stream acquired successfully.');
    } catch (e) {
      print('Error getting user media: $e');
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Could not get media: $e'),
            actions: <Widget>[
              TextButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return null;
    }
    return null;
  }

  void _handleBackSpace([bool deleteAll = false]) {
    var text = _textController!.text;
    if (text.isNotEmpty) {
      setState(() {
        text = deleteAll ? '' : text.substring(0, text.length - 1);
        _textController!.text = text;
      });
    }
  }

  void _handleNum(String number) {
    setState(() {
      _textController!.text += number;
    });
  }

  void handleSelectedNumber(String number) {
    setState(() {
      _textController!.text = number;
    });
  }

  List<Widget> _buildNumPad() {
    // final screenWidth = MediaQuery.of(context).size.width;
    final labels = [
      [
        {'1': ''},
        {'2': 'abc'},
        {'3': 'def'}
      ],
      [
        {'4': 'ghi'},
        {'5': 'jkl'},
        {'6': 'mno'}
      ],
      [
        {'7': 'pqrs'},
        {'8': 'tuv'},
        {'9': 'wxyz'}
      ],
      [
        {'*': ''},
        {'0': '+'},
        {'#': ''}
      ],
    ];

    return labels
        .map((row) => Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row
                    .map((label) => ActionButton(
                          title: label.keys.first,
                          subTitle: label.values.first,
                          onPressed: () => _handleNum(label.keys.first),
                          number: true,
                          textColor: Colors.white,
                          fillColor: Color.fromARGB(255, 61, 61, 61),
                          size: TargetPlatform.android ==
                                      defaultTargetPlatform ||
                                  TargetPlatform.iOS == defaultTargetPlatform
                              ? 50
                              : 40,
                        ))
                    .toList())))
        .toList();
  }

  List<Widget> _buildDialPad() {
    return [
      // Align(
      //   alignment: AlignmentDirectional.center,
      //   child: Text('Destination URL'),
      // ),
      TargetPlatform.android == defaultTargetPlatform ||
              TargetPlatform.iOS == defaultTargetPlatform
          ? const SizedBox(height: 40)
          : const SizedBox(height: 0),
      Container(
        width: 500,
        child: TextField(
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter a mobile number...',
          ),
          controller: _textController,
        ),
      ),
      TargetPlatform.android == defaultTargetPlatform ||
              TargetPlatform.iOS == defaultTargetPlatform
          ? const SizedBox(height: 30)
          : const SizedBox(height: 10),
      Container(
        width: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: _buildNumPad(),
        ),
      ),
      Container(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // ActionButton(
              //   icon: Icons.history,
              //   fillColor: Color.fromARGB(255, 47, 47, 47),
              //   textColor: Colors.white,
              //   onPressed: () => Navigator.push(context,
              //       MaterialPageRoute(builder: (context) => CallHistoryPage())),
              // ),
              ActionButton(
                icon: Icons.call,
                fillColor: Color.fromARGB(255, 15, 113, 230),
                onPressed: () => _handleCall(context, true),
                size: TargetPlatform.android == defaultTargetPlatform ||
                        TargetPlatform.iOS == defaultTargetPlatform
                    ? 50
                    : 40,
                iconSize: 30,
              ),
              // ActionButton(
              //   icon: Icons.keyboard_arrow_left,
              //   fillColor: Colors.redAccent,
              //   onPressed: () => _handleBackSpace(),
              //   onLongPress: () => _handleBackSpace(true),
              // ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 800; // Threshold for wide screens
    print('height: ${MediaQuery.of(context).size.height}');
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text("MCT Soft Phone"),
        ),
        leading: isWideScreen
            ? null
            : IconButton(
                icon: Icon(Icons.history),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CallHistoryPage(
                                helper: helper,
                                preferences: _preferences,
                                handleSelectedNumber: handleSelectedNumber,
                                isWideScreen: isWideScreen,
                              )));
                },
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              helper!.unregister(true);
              // _preferences.clear();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(
          255,
          36,
          36,
          36,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Registration State: ${helper!.registerState.state == RegistrationStateEnum.REGISTERED ? 'Registered' : 'Not Registered'}',
              style: TextStyle(
                  fontSize: 16,
                  color: helper!.registerState.state ==
                          RegistrationStateEnum.REGISTERED
                      ? Colors.green
                      : Colors.red),
            ),
          ],
        ),
      ),
      body: TargetPlatform.android == defaultTargetPlatform ||
              TargetPlatform.iOS == defaultTargetPlatform
          ? ListView(
              padding: EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                // SizedBox(height: 12),
                // Center(
                //   child: Text(
                //     'Received Message: $receivedMsg',
                //     style: TextStyle(fontSize: 16, color: Colors.black54),
                //   ),
                // ),
                SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildDialPad(),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Current User: ${_username ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            )
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                print('constraints: ${constraints.constrainHeight()}');
                if (isWideScreen) {
                  // Wide screen layout: side-by-side
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildDialContent(constraints.constrainHeight()),
                      ),
                      Expanded(
                        child: CallHistoryPage(
                          helper: helper,
                          preferences: _preferences,
                          handleSelectedNumber: handleSelectedNumber,
                          isWideScreen: isWideScreen,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Narrow screen layout: dial pad only
                  return _buildDialContent(constraints.constrainHeight());
                }
              },
            ),
      // body: _buildDialContent(MediaQuery.of(context).size.height),
    );
  }

  Widget _buildVerticalLayout(height, isWideScreen) {
    print('Building vertical layout...');
    return Column(
      children: <Widget>[
        Expanded(
          child: _buildDialContent(height),
        ),
        Expanded(
          child: CallHistoryPage(
            helper: helper,
            preferences: _preferences,
            handleSelectedNumber: handleSelectedNumber,
            isWideScreen: isWideScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(height, isWideScreen) {
    print('Building horizontal layout...');
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildDialContent(height),
        ),
        Expanded(
          child: CallHistoryPage(
            helper: helper,
            preferences: _preferences,
            handleSelectedNumber: handleSelectedNumber,
            isWideScreen: isWideScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildDialContent(double height) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 12),
      shrinkWrap: false,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildDialPad(),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
            'Current User: ${_username ?? 'Unknown'}',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
    // return SizedBox(
    //   height: TargetPlatform.android == defaultTargetPlatform ||
    //           TargetPlatform.iOS == defaultTargetPlatform
    //       ? // get maximum height for mobile devices
    //       height
    //       : 500,
    //   child: ListView(
    //     padding: EdgeInsets.symmetric(horizontal: 12),
    //     children: <Widget>[
    //       Column(
    //         crossAxisAlignment: CrossAxisAlignment.center,
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: _buildDialPad(height),
    //       ),
    //       SizedBox(height: 20),
    //       Center(
    //         child: Text(
    //           'Current User: ${_username ?? 'Unknown'}',
    //           style: TextStyle(
    //             fontSize: 18,
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {});
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void callStateChanged(Call call, CallState callState) {
    if (callState.state == CallStateEnum.CALL_INITIATION) {
      Navigator.pushNamed(context, '/callscreen', arguments: call);
    } else if (callState.state == CallStateEnum.FAILED) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Call Failed'),
            content: Text(callState.cause!.cause ?? 'Unknown Reason'),
            actions: <Widget>[
              TextButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // SIPMessageRequest(this.message, this.originator, this.request);

    String? msgBody = msg.request.body as String?;
    if (msg.originator.toString() == 'remote') {
      _logCall(
          'Incoming', 'Received message from: ${msg.originator.toString()}');
    }

    setState(() {
      receivedMsg = msgBody;
    });
  }

  @override
  void onNewNotify(Notify ntf) {}
}

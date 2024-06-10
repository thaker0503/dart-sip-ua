import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

class AuthenticationPage extends StatefulWidget {
  final SIPUAHelper? _helper;

  AuthenticationPage(this._helper, {Key? key}) : super(key: key);

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    implements SipUaHelperListener {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _subdomainController = TextEditingController();

  final List<String> _domains = ['.mctpbx.com', '.callconnects.site'];
  String _selectedDomain = '.mctpbx.com';

  late SharedPreferences _preferences;
  late RegistrationState _registerState;

  SIPUAHelper? get helper => widget._helper;

  @override
  void initState() {
    super.initState();
    _registerState = helper!.registerState;
    helper!.addSipUaHelperListener(this);
    _loadSettings();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _registerState = state;
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    helper!.removeSipUaHelperListener(this);
    _saveSettings();
  }

  void _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = _preferences.getString('auth_user') ?? '';
      _passwordController.text = _preferences.getString('password') ?? '';
      _subdomainController.text = _preferences.getString('domain') ?? '';
    });
  }

  void _saveSettings() async {
    await _preferences.setString('auth_user', _usernameController.text);
    await _preferences.setString('password', _passwordController.text);
    await _preferences.setString('domain', _subdomainController.text);
  }

  void _alert(BuildContext context, String alertFieldName) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$alertFieldName is empty'),
          content: Text('Please enter $alertFieldName!'),
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

  Future<void> _saveCredentialsAndRegisterSIP() async {
    if (_usernameController.text.isEmpty) {
      _alert(context, 'Username');
      return;
    } else if (_passwordController.text.isEmpty) {
      _alert(context, 'Password');
      return;
    } else if (_subdomainController.text.isEmpty) {
      _alert(context, 'Subdomain');
      return;
    } else if (_subdomainController.text.contains(' ')) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Invalid subdomain'),
            content: Text('Subdomain cannot contain spaces!'),
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
      return;
    } else if (_subdomainController.text.contains('@')) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Invalid subdomain'),
            content: Text('Subdomain cannot contain @ symbol!'),
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
      return;
    } else if (_subdomainController.text.contains('.')) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Invalid subdomain'),
            content: Text('Subdomain cannot contain . symbol!'),
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
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String fullDomain = _subdomainController.text.isNotEmpty
        ? "${_subdomainController.text}$_selectedDomain"
        : _selectedDomain;

    // Save credentials
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('domain', _subdomainController.text);
    // await prefs.setBool('isLoggedIn', true);

    // Prepare SIP registration settings
    UaSettings settings = UaSettings();

    String wsUri =
        'ws://$fullDomain:5066'; // Construct WebSocket URI, adjust as needed
    settings.webSocketUrl = wsUri;
    settings.webSocketSettings.extraHeaders =
        {}; // Add any extra headers if required
    settings.webSocketSettings.allowBadCertificate =
        true; // For self-signed certs, use with caution

    settings.uri = 'sip:${_usernameController.text}@$fullDomain:5066';
    settings.authorizationUser = _usernameController.text;
    settings.password =
        _passwordController.text; // Consider security implications
    settings.displayName = 'Flutter User'; // Or any display name you prefer
    settings.userAgent = '${_usernameController.text}@mct_sip_app';

    // Save SIP settings
    await prefs.setString('ws_uri', wsUri);
    await prefs.setString('sip_uri', settings.uri!);
    await prefs.setString('auth_user', settings.authorizationUser!);
    await prefs.setString('display_name', settings.displayName!);

    // Perform SIP registration
    await helper?.start(settings);
    print('State changed${helper!.registerState.state}');

    await prefs.setBool('isLoggedIn', true);
    // this.registrationStateChanged(helper!.registerState);

    await Future.delayed(Duration(seconds: 2));

    checkLoginStatus();

    // Navigate to the dialpad page or your main page here
    // Navigator.of(context).pushReplacementNamed('/dialpad');
  }

  void checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isLoggedIn') == true) {
      if (helper!.registerState.state == RegistrationStateEnum.REGISTERED) {
        Navigator.of(context).pushReplacementNamed('/dialpad');
      } else if (helper!.registerState.state ==
          RegistrationStateEnum.REGISTRATION_FAILED) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(helper!.registerState.cause.toString()),
        ));
      }
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('MCT Soft Phone'),
  //     ),
  //     body: SingleChildScrollView(
  //       padding: EdgeInsets.all(16),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           Text('Enter your credentials'),
  //           TextField(
  //             controller: _usernameController,
  //             decoration: InputDecoration(
  //                 labelText: 'Username', icon: Icon(Icons.person)),
  //           ),
  //           TextField(
  //             controller: _passwordController,
  //             obscureText: true, // To hide password input
  //             decoration: InputDecoration(
  //                 labelText: 'Password', icon: Icon(Icons.lock)),
  //           ),
  //           Row(
  //             children: <Widget>[
  //               Expanded(
  //                 flex: 1, // Adjust the ratio based on your layout needs
  //                 child: TextField(
  //                   controller: _subdomainController,
  //                   decoration: InputDecoration(
  //                     hintText: 'Subdomain',
  //                     icon: Icon(Icons.domain),
  //                   ),
  //                 ),
  //               ),
  //               // SizedBox(width: 10), // Add some spacing between the fields
  //               Expanded(
  //                 flex: 1,
  //                 child: DropdownButtonFormField<String>(
  //                   value: _selectedDomain,
  //                   onChanged: (String? newValue) {
  //                     setState(() {
  //                       _selectedDomain = newValue!;
  //                     });
  //                   },
  //                   items:
  //                       _domains.map<DropdownMenuItem<String>>((String value) {
  //                     return DropdownMenuItem<String>(
  //                       value: value,
  //                       child: Text(value),
  //                     );
  //                   }).toList(),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 20),
  //           ElevatedButton(
  //             style: ButtonStyle(
  //               padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
  //                 EdgeInsets.all(16),
  //               ),
  //               textStyle: MaterialStateProperty.all<TextStyle>(
  //                 TextStyle(fontSize: 18),
  //               ),
  //               minimumSize: MaterialStateProperty.all<Size>(
  //                 Size(double.infinity, 0),
  //               ),
  //             ),
  //             onPressed: _saveCredentialsAndRegisterSIP,
  //             child: Text('Submit'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; // Get screen width
    bool isDesktop =
        screenWidth > 600; // Assuming 600 as a breakpoint for desktop

    return Scaffold(
      appBar: AppBar(
        title: Text('MCT Soft Phone'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isDesktop ? 600 : screenWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Enter your credentials'),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person,
                ),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 20),
                _buildSubdomainRow(),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    textStyle: TextStyle(fontSize: isDesktop ? 18 : 14),
                    minimumSize: Size(double.infinity, 50), // Button height
                  ),
                  onPressed: _saveCredentialsAndRegisterSIP,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {TextEditingController? controller,
      String? label,
      String? hint,
      IconData? icon,
      bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hint,
      ),
    );
  }

  Widget _buildSubdomainRow() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildTextField(
            controller: _subdomainController,
            hint: 'Subdomain',
            icon: Icons.domain,
          ),
        ),
        // SizedBox(width: 10), // Space between fields
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDomain,
            onChanged: (String? newValue) {
              setState(() {
                _selectedDomain = newValue!;
              });
            },
            items: _domains.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  void callStateChanged(Call call, CallState state) {
    //NO OP
    print('Call state changed');
  }

  @override
  void transportStateChanged(TransportState state) {
    print('transport state changed');
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    print('Incoming message: ${msg.message}');
    SnackBar(
      content: Text('Incoming message: ${msg.message}'),
    );
  }

  @override
  void onNewNotify(Notify ntf) {
    // NO OP
    print('Incoming notify: ${ntf.toString()}');
  }
}

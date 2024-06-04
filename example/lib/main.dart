import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lottie/lottie.dart';
import 'package:mct_calling_app/src/login.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

import 'src/about.dart';
import 'src/callscreen.dart';
import 'src/dialpad.dart';
import 'src/register.dart';

void main() {
  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  runApp(MyApp());
}

typedef PageContentBuilder = Widget Function(
    [SIPUAHelper? helper, Object? arguments]);

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  final SIPUAHelper _helper = SIPUAHelper();

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return ((prefs.getBool('isLoggedIn') ?? false) &&
        _helper.registerState.state == RegistrationStateEnum.REGISTERED);
  }

  Map<String, PageContentBuilder> routes = {
    '/login': ([SIPUAHelper? helper, Object? arguments]) =>
        AuthenticationPage(helper),
    '/': ([SIPUAHelper? helper, Object? arguments]) => DialPadWidget(helper),
    '/register': ([SIPUAHelper? helper, Object? arguments]) =>
        RegisterWidget(helper),
    '/callscreen': ([SIPUAHelper? helper, Object? arguments]) =>
        CallScreenWidget(helper, arguments as Call?),
    '/about': ([SIPUAHelper? helper, Object? arguments]) => AboutWidget(),
  };

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final String? name = settings.name;
    final PageContentBuilder? pageContentBuilder = routes[name!];
    if (pageContentBuilder != null) {
      if (settings.arguments != null) {
        final Route route = MaterialPageRoute<Widget>(
            builder: (context) =>
                pageContentBuilder(_helper, settings.arguments));
        return route;
      } else {
        final Route route = MaterialPageRoute<Widget>(
            builder: (context) => pageContentBuilder(_helper));
        return route;
      }
    }
    return null;
  }

  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     title: 'MCT APP',
  //     theme: ThemeData(
  //       primarySwatch: Colors.blue,
  //       fontFamily: 'Roboto',
  //       inputDecorationTheme: InputDecorationTheme(
  //         hintStyle: TextStyle(color: Colors.grey),
  //         contentPadding: EdgeInsets.all(10.0),
  //         border: UnderlineInputBorder(
  //             borderSide: BorderSide(color: Colors.black12)),
  //       ),
  //       elevatedButtonTheme: ElevatedButtonThemeData(
  //         style: ElevatedButton.styleFrom(
  //           padding: const EdgeInsets.all(16),
  //           textStyle: TextStyle(fontSize: 18),
  //         ),
  //       ),
  //     ),
  //     initialRoute: isLoggedIn() ? '/' : '/login',
  //     onGenerateRoute: _onGenerateRoute,
  //     onUnknownRoute: (settings) => MaterialPageRoute(
  //         builder: (context) =>
  //             isLoggedIn() ? DialPadWidget(_helper) : AuthenticationPage()),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCT APP',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 36, 36, 36),
        ),
        scaffoldBackgroundColor: Color.fromARGB(255, 36, 36, 36),
      ), // Use the system theme
      home: AnimatedSplashScreen(
        splash: Lottie.asset('assets/animations/splash-screen.json'),
        nextScreen: FutureBuilder<bool>(
          future: isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data == true) {
              return DialPadWidget(_helper); // Your main screen widget
            } else {
              return AuthenticationPage(_helper); // Your login screen widget
            }
          },
        ),
        splashTransition: SplashTransition.fadeTransition,
        backgroundColor: Color.fromARGB(
          255,
          36,
          36,
          36,
        ),
        duration: 3000,
      ),
      onGenerateRoute: _onGenerateRoute,
      // Handle unknown routes. Adjust according to your app's navigation logic
      onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => FutureBuilder<bool>(
                future: isLoggedIn(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data == true) {
                    return DialPadWidget(_helper); // Your main screen widget
                  } else {
                    return AuthenticationPage(
                        _helper); // Your login screen widget
                  }
                },
              )),
    );
  }
}

// theme: ThemeData(
      //   primarySwatch: Colors.blue,
      //   fontFamily: 'Roboto',
      //   inputDecorationTheme: InputDecorationTheme(
      //     hintStyle: TextStyle(color: Colors.grey),
      //     contentPadding: EdgeInsets.all(10.0),
      //     border: UnderlineInputBorder(
      //         borderSide: BorderSide(color: Colors.black12)),
      //   ),
      //   elevatedButtonTheme: ElevatedButtonThemeData(
      //     style: ElevatedButton.styleFrom(
      //       padding: const EdgeInsets.all(16),
      //       textStyle: TextStyle(fontSize: 18),
      //     ),
      //   ),
      // ),


      // FutureBuilder<bool>(
      //   future: isLoggedIn(),
      //   builder: (context, snapshot) {
      //     // Check if the future is complete
      //     if (snapshot.connectionState == ConnectionState.done) {
      //       if (snapshot.data == true) {
      //         // User is logged in, navigate to the main screen
      //         return DialPadWidget(
      //             _helper); // Assuming DialPadWidget is your main screen after login
      //       } else {
      //         // User is not logged in, show the login screen
      //         return AuthenticationPage(); // Assuming AuthenticationPage is your login screen
      //       }
      //     } else {
      //       // While waiting, show a loading indicator
      //       return Center(child: CircularProgressIndicator());
      //     }
      //   },
      // ),
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

//import 'video_list.dart';

void main() {
  //runApp(YoutubePlayerDemoApp());
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '',
    home: WelcomeScreen(),
  ));
}

/// Creates [YoutubePlayerDemoApp] widget.
class YoutubePlayerDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Youtube Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: Colors.blueAccent,
        ),
        iconTheme: const IconThemeData(
          color: Colors.blueAccent,
        ),
      ),
      home: MyHomePage(),
    );
  }
}

/// Homepage
String _ids = 'vSEb-ecFrRE';
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late YoutubePlayerController _controller;
  late TextEditingController _idController;
  late TextEditingController _seekToController;

  late PlayerState _playerState;
  late YoutubeMetaData _videoMetaData;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(_ids).toString(),
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: true,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(listener);
    //if (!_controller.value.isFullScreen) {
    _controller.toggleFullScreenMode();
    //}
    _idController = TextEditingController();
    _seekToController = TextEditingController();
    _videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
        _videoMetaData = _controller.metadata;
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    _seekToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        log('onEnterFullScreen');
        SystemChrome.setPreferredOrientations(
            [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
        );
      },
      onExitFullScreen: () {
        log('onExitFullScreen');
        // The player forces portraitUp after exiting fullscreen. This overrides the behaviour.
        //SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        onReady: () {
          log('ThienDT: Video ready');
        },
        onEnded: (data) {
          log('ThienDT: End video');
        },
      ),
        builder: (context, player) {
          return Column(
            children: [
              // some widgets
              player,
              //some other widgets
            ],
          );
        },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WelcomeScreen'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Scan'),
          onPressed: () {
            // Navigate to second route when tapped.
            Navigator.push(
              context,
              //MaterialPageRoute(builder: (context) => YoutubePlayerDemoApp()),
              MaterialPageRoute(builder: (context) => QRScanner()),
            );
          },
        ),
      ),
    );
  }
}

class QRScanner extends StatefulWidget {
  const QRScanner({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        if (scanData.code != null) {
          reassemble();
          _ids = scanData.code.toString();
          log('ThienDT - _onQRViewCreated:' + _ids);

          //Open URL Launcher
          _launchURL();

//          Navigator.push(
//            context,
//            //MaterialPageRoute(builder: (context) => YoutubePlayerDemoApp()),
//            MaterialPageRoute(builder: (context) => YoutubePlayerDemoApp()),
//          );
        }
      });
    });
  }

  void _launchURL() async {
    if (!await launch (_ids,
        forceWebView: true,
        enableJavaScript: true,
    )) {
      throw 'Could not launch $_ids';
    }
  }

  @override
  void dispose() {
    log('QR Controller Dispose');
    controller?.dispose();
    super.dispose();
  }
}
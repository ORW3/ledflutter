import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:starsview/config/MeteoriteConfig.dart';
import 'package:starsview/config/StarsConfig.dart';
import 'package:starsview/starsview.dart';
import 'package:permission_handler/permission_handler.dart'; // Importación para gestionar permisos
import 'dart:ui';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return NeumorphicApp(
      title: 'LED Controller',
      themeMode: ThemeMode.light,
      theme: NeumorphicThemeData(
        baseColor: Color.fromARGB(255, 232, 224, 237),
        lightSource: LightSource.topLeft,
        depth: 4,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothConnection? connection;
  Color currentColor = Color.fromARGB(255, 173, 0, 255);
  double intensity = 1.0;
  bool isConnected = false;
  bool isOn = true;
  Timer? _timer; // Declarar un Timer

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startConnectionCheck(); // Iniciar el chequeo de la conexión
  }

  Future<void> _requestPermissions() async {
    var status = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location
    ].request();

    if (status[Permission.bluetooth]!.isGranted &&
        status[Permission.bluetoothConnect]!.isGranted &&
        status[Permission.bluetoothScan]!.isGranted &&
        status[Permission.location]!.isGranted) {
      // Permisos concedidos
    } else {
      print("Permisos no concedidos");
    }
  }

  Future<void> _connectToDevice() async {
    try {
      var devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (var device in devices) {
        if (device.name == "ESP32_LED_Control") {
          connection = await BluetoothConnection.toAddress(device.address);
          setState(() {
            isConnected = true;
          });
          break;
        }
      }
      if (!isConnected) {
        print("No se encontró el dispositivo ESP32_LED_Control");
      }
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

  void _sendData(String command) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(Uint8List.fromList(utf8.encode(command)));
    }
  }

  void _toggleLed() {
    if (isOn) {
      _sendData("OFF\n");
    } else {
      _sendData(
          "${currentColor.red},${currentColor.green},${currentColor.blue},${(intensity * 100).toInt()}\n");
    }
    setState(() {
      isOn = !isOn;
    });
  }

  void _startConnectionCheck() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (connection != null) {
        setState(() {
          isConnected = connection!.isConnected;
        });
      } else {
        setState(() {
          isConnected = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.fromARGB(255, 9, 6, 26),
                    Color.fromARGB(255, 18, 12, 52),
                    Color.fromARGB(255, 232, 224, 237),
                    Color.fromARGB(255, 232, 224, 237),
                  ],
                ),
              ),
            ),
            FractionallySizedBox(
              heightFactor: 0.4,
              child: StarsView(
                fps: 60,
                starsConfig: StarsConfig(minStarSize: 0, maxStarSize: 2),
                meteoriteConfig: MeteoriteConfig(enabled: false),
              ),
            ),
            AppBar(
              toolbarHeight: 80,
              backgroundColor: Colors.transparent,
              actions: [
                IconButton(
                  padding: EdgeInsets.only(top: 20, bottom: 10),
                  icon: SimpleShadow(
                    opacity: 0.4,
                    color: Colors.white,
                    offset: Offset(0, 0),
                    sigma: 5,
                    child: Image.asset(
                      'assets/images/luna.png',
                    ),
                  ),
                  onPressed: () {},
                ),
                SizedBox(width: 20),
              ],
              elevation: 0,
            ),
            Column(
              children: <Widget>[
                SizedBox(height: 50),
                SimpleShadow(
                  opacity: 0.6,
                  color: currentColor,
                  offset: Offset(5, 0),
                  sigma: 30,
                  child: InnerShadow(
                    child: Transform.translate(
                      offset: Offset(-40, 0),
                      child: Image.asset(
                        'assets/images/cuarto.png',
                      ),
                    ),
                    shadows: [
                      Shadow(
                          color: currentColor,
                          blurRadius: 80,
                          offset: const Offset(2, 5))
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NeumorphicButton(
                      onPressed: _connectToDevice,
                      style: NeumorphicStyle(
                        color: Color.fromARGB(255, 232, 224, 237),
                      ),
                      child:
                          isConnected ? Text('Desconectar') : Text('Conectar'),
                    ),
                    isConnected
                        ? isOn
                            ? NeumorphicButton(
                                onPressed: _toggleLed,
                                child: SimpleShadow(
                                  sigma: 2,
                                  color: Color.fromARGB(255, 255, 214, 0),
                                  opacity: 1,
                                  offset: Offset(0, 0),
                                  child: Image.asset(
                                    "assets/images/foco.png",
                                    height: 40,
                                    color: Color.fromARGB(255, 255, 214, 0),
                                  ),
                                ),
                                style: NeumorphicStyle(
                                  boxShape: NeumorphicBoxShape.circle(),
                                  shape: NeumorphicShape.concave,
                                  color: Color.fromARGB(255, 38, 24, 114),
                                ),
                              )
                            : NeumorphicButton(
                                onPressed: _toggleLed,
                                child: Image.asset(
                                  "assets/images/foco.png",
                                  height: 40,
                                ),
                                style: NeumorphicStyle(
                                  boxShape: NeumorphicBoxShape.circle(),
                                  shape: NeumorphicShape.concave,
                                  color: Color.fromARGB(255, 9, 6, 26),
                                ),
                              )
                        : Text(
                            'Sin conexión',
                            style: TextStyle(color: currentColor, fontSize: 15),
                          ),
                  ],
                ),
                SizedBox(height: 40),
                ColorPicker(
                  pickerColor: currentColor,
                  onColorChanged: (color) {
                    setState(() {
                      currentColor = Color.fromARGB(
                          (intensity * 255).round().toInt(),
                          color.red,
                          color.green,
                          color.blue);
                    });
                    _sendData(
                        "${currentColor.red},${currentColor.green},${currentColor.blue},${(intensity * 100).toInt()}\n");
                  },
                  showLabel: false,
                  hexInputBar: true,
                  enableAlpha: false,
                  displayThumbColor: true,
                  pickerAreaHeightPercent: 0,
                ),
                InteractiveSlider(
                  startIcon: Neumorphic(
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.convex,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(100)),
                      depth: 2,
                      intensity: 0.9,
                      lightSource: LightSource.topLeft,
                      surfaceIntensity: 0.4,
                    ),
                    child: Container(
                      height: 50,
                      width: 50,
                      child: Icon(
                        Icons.bolt,
                        size: 34,
                        color: Color.fromARGB(255, 67, 57, 116),
                      ),
                    ),
                  ),
                  unfocusedMargin: EdgeInsets.zero,
                  unfocusedHeight: 80,
                  focusedHeight: 80,
                  iconPosition: IconPosition.inside,
                  min: 0,
                  max: 1,
                  initialProgress: intensity,
                  foregroundColor: currentColor,
                  onChanged: (value) {
                    setState(() {
                      intensity = value;
                      currentColor = Color.fromARGB(
                          (value * 255).round().toInt(),
                          currentColor.red,
                          currentColor.green,
                          currentColor.blue);
                    });
                    _sendData(
                        "${currentColor.red},${currentColor.green},${currentColor.blue},${(intensity * 100).toInt()}\n");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el Timer al descartar el widget
    connection?.dispose();
    super.dispose();
  }
}

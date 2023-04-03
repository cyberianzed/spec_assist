import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../ble/SelectBondedDevicePage.dart';
import 'speech_main.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          Icons.menu,
          color: Colors.black,
        ),
        title: Center(
            child: Text(
          "SpecAssist Connect",
          style: TextStyle(color: Colors.black, fontSize: 13),
        )),
        backgroundColor: Color.fromARGB(226, 243, 237, 247),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No devices connected"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              // onPressed: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => MainPage(),
              //     ),
              //   );
              // },
              onPressed: () async {
                final BluetoothDevice? selectedDevice =
                    await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return SelectBondedDevicePage(checkAvailability: false);
                    },
                  ),
                );

                if (selectedDevice != null) {
                  print('Connect -> selected ' + selectedDevice.address);
                  _startChat(context, selectedDevice);
                  // setServer(server);
                } else {
                  print('Connect -> no device selected');
                }
              },
              icon: Icon(Icons.add),
              label: Text('Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 73, 0, 220),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return SpeechSampleApp(server: server);
          // return SpeechSampleApp();
        },
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../model/prompt.dart';

class SpeechSampleApp extends StatefulWidget {
  final BluetoothDevice server;

  SpeechSampleApp({Key? key, required this.server}) : super(key: key);
  @override
  _SpeechSampleAppState createState() => _SpeechSampleAppState();
}

/// An example that demonstrates the basic functionality of the
/// SpeechToText plugin for using the speech recognition capability
/// of the underlying platform.
class _SpeechSampleAppState extends State<SpeechSampleApp> {
  ChatGPT? _chatGPT;
  // List<String> messages = [];
  BluetoothConnection? connection;
  // final ScrollController listScrollController = new ScrollController();
  String _messageBuffer = '';
  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;

  bool _hasSpeech = false;
  bool _logEvents = false;
  bool _onDevice = false;
  // bool _getpro = false;
  final TextEditingController _pauseForController =
      TextEditingController(text: '8');
  final TextEditingController _listenForController =
      TextEditingController(text: '50');
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String response = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  @override
  void initState() {
    super.initState();
    _chatGPT = ChatGPT();
  }

  Future<void> _sendQuery(String query) async {
    print('query : ' + query);
    try {
      response = await _chatGPT!.getResponse(query);
      print('response : ' + response);
    } catch (e) {
      print(e.toString());
    }
  }

  //TODO rnpromp

  // Future<void> run_prompt() async {
  //   // if (_getpro) {
  //   //   _getpro = false;
  //   // }
  //   if (_getpro) {
  //     _sendQuery('give only the response as a human for ' + lastWords);
  //     print('response : ' + response);
  //     _sendMessage(response);
  //   }
  // }

  /// This initializes SpeechToText. That only has to be done
  /// once per application, though calling it again is harmless
  /// it also does nothing. The UX of the sample app ensures that
  /// it can only be called once.
  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: _logEvents,
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await speech.locales();

        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text'),
      ),
      body: Column(children: [
        Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InitSpeechWidget(_hasSpeech, initSpeechState),
              SpeechControlWidget(_hasSpeech, speech.isListening,
                  startListening, stopListening, cancelListening),
              SessionOptionsWidget(
                _currentLocaleId,
                _switchLang,
                _localeNames,
                _logEvents,
                _switchLogging,
                _pauseForController,
                _listenForController,
                _onDevice,
                _switchOnDevice,
              ),
              SizedBox(
                height: 30,
              ),
              (isConnecting
                  ? Text('Connecting ...')
                  : isConnected
                      // ? conect_message(serverName)
                      ? Text('Connected with ' + serverName)
                      : Text('log with ' + serverName)),
              SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
        Expanded(
            flex: 5,
            // child: RecognitionResultsWidget(lastWords: lastWords, level: level),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Container(
                        color: Theme.of(context).selectedRowColor,
                        child: Center(
                          child: Text(
                            lastWords,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        bottom: 10,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: .26,
                                    spreadRadius: level * 1.5,
                                    color: Color.fromARGB(255, 246, 3, 3)
                                        .withOpacity(.05))
                              ],
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                            ),
                            child: IconButton(
                                icon: Icon(Icons.mic), onPressed: () => {}),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )),
        // Expanded(
        //   flex: 2,
        //   child: ListView.builder(
        //     controller: listScrollController,
        //     itemCount: messages.length,
        //     itemBuilder: (context, index) {
        //       return ListTile(title: Text(messages[index]));
        //     },
        //   ),
        // ),
        Expanded(
          flex: 1,
          child: TextButton(
            onPressed: () async {
              await _sendQuery(
                  'give only the response as a human for ' + lastWords);
              print(response);
              await _sendMessage(response);
              setState(() {});
            },
            child: Text('Get Prompt'),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(response),
        ),
        Expanded(
          flex: 1,
          child: ErrorWidget(lastError: lastError),
        ),
        // SpeechStatusWidget(speech: speech),
        Center(
          child: speech.isListening
              ? Text(
                  "listening...",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              : SizedBox(),
        ),
      ]),
    );
  }

  // This is called each time the users wants to start a new speech
  // recognition session
  void startListening() {
    _logEvent('start listening');
    lastWords = '';
    lastError = '';
    final pauseFor = int.tryParse(_pauseForController.text);
    final listenFor = int.tryParse(_listenForController.text);
    // Note that `listenFor` is the maximum, not the minimun, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: listenFor ?? 30),
      pauseFor: Duration(seconds: pauseFor ?? 3),
      partialResults: true,
      localeId: _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
      onDevice: _onDevice,
    );
    setState(() {});
  }

  void stopListening() {
    _logEvent('stop');
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    _logEvent('cancel');
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    _logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      //TODO voice string
      lastWords = '${result.recognizedWords} ';
    });
    print(lastWords);
    _sendMessage(lastWords);
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // _logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
        'Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = '$status';
    });
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      print('$eventTime $eventDescription');
    }
  }

  void _switchLogging(bool? val) {
    setState(() {
      _logEvents = val ?? false;
    });
  }

  void _switchOnDevice(bool? val) {
    setState(() {
      _onDevice = val ?? false;
    });
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  Future<void> _sendMessage(String text) async {
    text = text.trim();
    print(text);

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;
        // run_prompt();
        setState(() {
          // messages.add(text);
        });
        // run_prompt();

        // Future.delayed(Duration(milliseconds: 333)).then((_) {
        //   listScrollController.animateTo(
        //       listScrollController.position.maxScrollExtent,
        //       duration: Duration(milliseconds: 333),
        //       curve: Curves.easeOut);
        // }
        // );
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  // SizedBox send_to() {
  //   _sendQuery('give only the response as a human for ' + lastWords);
  //   _sendMessage(lastWords);
  //   return SizedBox();
  // }
}

/// Displays the most recently recognized words and the sound level.
class RecognitionResultsWidget extends StatelessWidget {
  const RecognitionResultsWidget({
    Key? key,
    required this.lastWords,
    required this.level,
  }) : super(key: key);

  final String lastWords;
  final double level;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: <Widget>[
              Container(
                color: Theme.of(context).selectedRowColor,
                child: Center(
                  child: Text(
                    lastWords,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Positioned.fill(
                bottom: 10,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            blurRadius: .26,
                            spreadRadius: level * 1.5,
                            color: Colors.black.withOpacity(.05))
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.mic),
                      onPressed: () => {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Display the current error status from the speech
/// recognizer
class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    Key? key,
    required this.lastError,
  }) : super(key: key);

  final String lastError;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Center(
          child: Text(
            lastError,
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

/// Controls to start and stop speech recognition
class SpeechControlWidget extends StatelessWidget {
  SpeechControlWidget(this.hasSpeech, this.isListening, this.startListening,
      this.stopListening, this.cancelListening);

  final bool hasSpeech;
  final bool isListening;
  final void Function() startListening;
  final void Function() stopListening;
  final void Function() cancelListening;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: !hasSpeech || isListening ? null : startListening,
          child: Text('Start'),
        ),
        //TODO start
        TextButton(
          onPressed: () {
            isListening ? stopListening : null;
            // _sendMessage("lastWords");
            //     connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
            // await connection!.output.allSent;
          },
          child: Text('Stop'),
        ),
        TextButton(
          onPressed: isListening ? cancelListening : null,
          child: Text('Cancel'),
        )
      ],
    );
  }
}

class SessionOptionsWidget extends StatelessWidget {
  const SessionOptionsWidget(
      this.currentLocaleId,
      this.switchLang,
      this.localeNames,
      this.logEvents,
      this.switchLogging,
      this.pauseForController,
      this.listenForController,
      this.onDevice,
      this.switchOnDevice,
      {Key? key})
      : super(key: key);

  final String currentLocaleId;
  final void Function(String?) switchLang;
  final void Function(bool?) switchLogging;
  final void Function(bool?) switchOnDevice;
  final TextEditingController pauseForController;
  final TextEditingController listenForController;
  final List<LocaleName> localeNames;
  final bool logEvents;
  final bool onDevice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Language: '),
          DropdownButton<String>(
            onChanged: (selectedVal) => switchLang(selectedVal),
            value: currentLocaleId,
            items: localeNames
                .map(
                  (localeName) => DropdownMenuItem(
                    value: localeName.localeId,
                    child: Text(localeName.name),
                  ),
                )
                .toList(),
          ),
          Row(
            children: [
              Text('pauseFor: '),
              Container(
                  padding: EdgeInsets.only(left: 8),
                  width: 80,
                  child: TextFormField(
                    controller: pauseForController,
                  )),
              Container(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('listenFor: ')),
              Container(
                  padding: EdgeInsets.only(left: 8),
                  width: 80,
                  child: TextFormField(
                    controller: listenForController,
                  )),
            ],
          ),
          // Row(
          //   children: [
          //     Text('On device: '),
          //     Checkbox(
          //       value: onDevice,
          //       onChanged: switchOnDevice,
          //     ),
          //     Text('Log events: '),
          //     Checkbox(
          //       value: logEvents,
          //       onChanged: switchLogging,
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class InitSpeechWidget extends StatelessWidget {
  const InitSpeechWidget(this.hasSpeech, this.initSpeechState, {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final Future<void> Function() initSpeechState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: hasSpeech ? null : initSpeechState,
          child: Text('Initialize'),
        ),
      ],
    );
  }
}

/// Display the current status of the listener
// class SpeechStatusWidget extends StatelessWidget {
//   const SpeechStatusWidget({
//     Key? key,
//     required this.speech,
//   }) : super(key: key);

//   final SpeechToText speech;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//         child: speech.isListening
//             ? Text(
//                 "listening...",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               )
//             : send_to());
//   }
// }

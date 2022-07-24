import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';
import 'dart:convert';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MqttServerClient client = MqttServerClient(Config.awsDataEndpoint, '');
  bool isConnected = false;
  String statusText = "Status Text";
  bool isPlaying = false;

  TextEditingController topicController =
      TextEditingController();
  TextEditingController payloadController = TextEditingController();

  //dropdown
  final List<String> items = [
    '15-minutes',
    '18-minutes',
    '25-minutes',
    '30-minutes',
    '40-minutes',
    '45-minutes',
    '1-hour',
    '1-hour-15-minutes',
    '1-hour-25-minutes',
    '1-hour-30-minutes',
    '1-hour-45-minutes',
    '2-hour',
  ];
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            //   height: MediaQuery.of(context).size.height - MediaQuery.of(context).viewPadding.top-MediaQuery.of(context).viewPadding.bottom,
            height: MediaQuery.of(context).size.height,
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  child: isConnected
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Text('Topic: ${topicController.text}'),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 8,
                          ),
                          child: TextFormField(
                            controller: topicController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Topic',
                              labelText: 'Topic',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.only(
                                  left: 14.0, bottom: 6.0, top: 8.0),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.teal),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  child: isConnected
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _disconnect();
                            },
                            style:
                                ElevatedButton.styleFrom(primary: Colors.red),
                            child: const Text('Disconnect'),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: ElevatedButton(
                            onPressed: () {
                              if(topicController.text.trim().isNotEmpty){
                              _connect();
                              } else {
                                const snackBar = SnackBar(
                                  content: Text('Add a Topic Man'),
                                  backgroundColor: Colors.green,
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              }
                            },
                            style:
                                ElevatedButton.styleFrom(primary: Colors.green),
                            child: const Text('Connect'),
                          ),
                        ),
                ),
                SizedBox(
                  child: isConnected
                      ? Column(
                          children: [
                            const SizedBox(
                              height: 24,
                            ),
                            const Divider(
                              color: Colors.teal,
                              thickness: 1,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextFormField(
                                controller: payloadController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Message',
                                  labelText: 'Message',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.only(
                                      left: 14.0, bottom: 6.0, top: 8.0),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: Colors.teal),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (payloadController.text.trim().isNotEmpty) {
                                  onPublishButtonPressed(
                                    topic: topicController.text,
                                    payload:
                                        '{"message": "${payloadController.text.trim()}"}',
                                  );
                                } else {
                                  const snackBar = SnackBar(
                                    content: Text('Type some text first.'),
                                    backgroundColor: Colors.teal,
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  primary: Colors.teal),
                              child: const Text('Publish'),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            const Divider(
                              color: Colors.pink,
                              thickness: 1,
                            ),
                            Center(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2(
                                  isExpanded: true,
                                  hint: Row(
                                    children: const [
                                      Icon(
                                        Icons.list,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Select Item',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  items: items
                                      .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  value: selectedValue,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedValue = value as String;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                  ),
                                  iconSize: 14,
                                  iconEnabledColor: Colors.white,
                                  iconDisabledColor: Colors.grey,
                                  buttonHeight: 50,
                                  buttonWidth: 160,
                                  buttonPadding: const EdgeInsets.only(
                                      left: 14, right: 14),
                                  buttonDecoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.black26,
                                    ),
                                    color: Colors.pink,
                                  ),
                                  buttonElevation: 2,
                                  itemHeight: 40,
                                  itemPadding: const EdgeInsets.only(
                                      left: 14, right: 14),
                                  dropdownMaxHeight: 200,
                                  dropdownWidth: 200,
                                  dropdownPadding: null,
                                  dropdownDecoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.pink,
                                  ),
                                  dropdownElevation: 8,
                                  scrollbarRadius: const Radius.circular(40),
                                  scrollbarThickness: 6,
                                  scrollbarAlwaysShow: true,
                                  offset: const Offset(-20, 0),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (selectedValue != null) {
                                  onPublishButtonPressed(
                                    topic: topicController.text,
                                    payload: '{"message": "$selectedValue"}',
                                  );
                                } else {
                                  const snackBar = SnackBar(
                                    content: Text('Select a value first'),
                                    backgroundColor: Colors.pink,
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  primary: Colors.pink),
                              child: const Text('Publish Wash Type'),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            Divider(
                              color: isPlaying ? Colors.orange : Colors.green,
                              thickness: 1,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (isPlaying) {
                                  onPublishButtonPressed(
                                    topic: topicController.text,
                                    payload: '{"message": "Pause"}',
                                  );
                                  isPlaying = false;
                                } else {
                                  onPublishButtonPressed(
                                    topic: topicController.text,
                                    payload: '{"message": "Play"}',
                                  );
                                  isPlaying = true;
                                }
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                  primary:
                                      isPlaying ? Colors.orange : Colors.green),
                              child: isPlaying
                                  ? const Text('Pause')
                                  : const Text('Play'),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            const Divider(
                              color: Colors.blue,
                              thickness: 1,
                            ),

                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: 80,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: 10,
                                itemBuilder: (context, index) => Container(
                                  margin: const EdgeInsets.all(8),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      onPublishButtonPressed(
                                        topic: topicController.text,
                                        payload:
                                            '{"message": "btn-${index + 1}"}',
                                      );
                                    },
                                    child: Text('Button-${index + 1}'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                          ],
                        )
                      : Container(),
                ),
                StreamBuilder(
                  stream: client.updates,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final mqttReceivedMessages = snapshot.data
                          as List<MqttReceivedMessage<MqttMessage?>>?;

                      final recMess = mqttReceivedMessages![0].payload
                          as MqttPublishMessage;

                      return isConnected
                          ? Text(
                              utf8.decode(recMess.payload.message).toString())
                          : const Text('');
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24.0, horizontal: 8),
                        child: Center(
                          child: Text(
                            'Connection Status: $isConnected',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _connect() async {
    //////Progress Dialog
    ProgressDialog progressDialog = ProgressDialog(
      context,
      blur: 0,
      dialogTransitionType: DialogTransitionType.Shrink,
      dismissable: false,
    );
    progressDialog.setLoadingWidget(
      const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.red),
      ),
    );
    progressDialog.setMessage(
      const Text("Please Wait, Connecting to AWS IoT MQTT Broker"),
    );
    progressDialog.setTitle(
      const Text("Connecting"),
    );
    progressDialog.show();

    isConnected = await mqttConnect('ss1994');

    progressDialog.dismiss();
  }

  _disconnect() {
    client.disconnect();
  }

  Future<bool> mqttConnect(String clientId) async {
    setStatus("Connecting MQTT Broker..........");

    ByteData rootCA = await rootBundle.load('assets/certs/RootCA.pem');
    ByteData deviceCert =
        await rootBundle.load('assets/certs/DeviceCertificate.crt');
    ByteData privateKey = await rootBundle.load('assets/certs/Private.key');

    SecurityContext context = SecurityContext.defaultContext;
    context.setClientAuthoritiesBytes(rootCA.buffer.asUint8List());
    context.useCertificateChainBytes(deviceCert.buffer.asUint8List());
    context.usePrivateKeyBytes(privateKey.buffer.asUint8List());

    client.securityContext = context;

    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.port = 8883;
    client.secure = true;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.pongCallback = pong;

    if (kDebugMode) {
      print(
          '#########################################: Updates :  ${client.updates}');
    }

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMess;

    if (kDebugMode) {
      print(
          '>>>>>>>>>>>>>>>>>>>>>>>>>Connection message>>>>>>>>>>>>>>>>>>>>: $connMess');
    }

    try {
      await client.connect();
    } catch (e) {
      if (kDebugMode) {
        print('>>>>>>>>>>>>>>>>>>>>>>>>>Exception>>>>>>>>>>>>>>>>>>>>: $e');
      }
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      if (kDebugMode) {
        print("Connected to AWS Successfully!");
      }
    } else {
      if (kDebugMode) {
        print("Connected to AWS was not Successfully!");
      }
      return false;
    }

    final topic = topicController.text.trim();
    // const topic = 'ESP32SIM800L-Test/ESP32SIM800L-Test-policy';
    client.subscribe(topic, MqttQos.atMostOnce);
    client.subscribe('s', MqttQos.atMostOnce);
    client.subscribe('ss', MqttQos.atMostOnce);
    client.subscribe('sss', MqttQos.atMostOnce);

    return true;
  }

  void setStatus(String content) {
    setState(() {
      statusText = content;
    });
  }

  void onConnected() {
    setStatus("Client connection was successful");
  }

  void onDisconnected() {
    setStatus("Client Disconnected");
    isConnected = false;
  }

  void pong() {
    if (kDebugMode) {
      print('Ping response client callback invoked');
    }
  }

  void onPublishButtonPressed({
    required String topic,
    required String payload,
  }) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}

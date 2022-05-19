import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';
import 'dart:convert';

// final mqttReceivedMessages = snapshot.data as List<MqttReceivedMessage<MqttMessage?>>?;
// final recMess = mqttReceivedMessages![0].payload as MqttPublishMessage;

// const awsDataEndpoint = 'abzdpvuwkaq5j-ats.iot.ap-southeast-1.amazonaws.com';
//const awsDataEndpoint = 'abzdpvuwkaq5j-ats.iot.ap-southeast-1.amazonaws.com';
const awsDataEndpoint = 'abzdpvuwkaq5j-ats.iot.ap-southeast-1.amazonaws.com';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final MqttServerClient client = MqttServerClient.withPort(awsDataEndpoint, 'ss-1994',8883,maxConnectionAttempts: 5);
  final MqttServerClient client = MqttServerClient(awsDataEndpoint, '');
  bool isConnected = false;
  String statusText = "Status Text";
  final s = 20000000;

  TextEditingController topicController =
      TextEditingController(text: 'things/FlutterTest');
  TextEditingController payloadController =
      TextEditingController(text: 'Hello from mobile Client');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              child: isConnected
                  ? Text('Topic: ${topicController.text}')
                  : Padding(
                      padding: const EdgeInsets.all(8),
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
                            borderSide: BorderSide(color: Colors.teal),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(
              child: isConnected
                  ? ElevatedButton(
                      onPressed: () {
                        _disconnect();
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.red),
                      child: const Text('Disconnect'),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        _connect();
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.green),
                      child: const Text('Connect'),
                    ),
            ),
            SizedBox(
              child: isConnected
                  ? Column(
                      children: [
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
                                borderSide: BorderSide(color: Colors.teal),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            onPublishButtonPressed(
                              topic: topicController.text,
                              payload:
                                  '{\"message\": \"${payloadController.text}\"}',
                            );
                          },
                          style: ElevatedButton.styleFrom(primary: Colors.teal),
                          child: const Text('Publish'),
                        )
                      ],
                    )
                  : Container(),
            ),
            StreamBuilder(
              stream: client.updates,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final mqttReceivedMessages =
                      snapshot.data as List<MqttReceivedMessage<MqttMessage?>>?;

                  final recMess =
                      mqttReceivedMessages![0].payload as MqttPublishMessage;

                  // img.Image jpegImage = img.decodeJpg(recMess.payload.message!);
                  return isConnected
                      ? Text(utf8.decode(recMess.payload.message).toString())
                      : Text('');
                } else {
                  return Center(
                    child: Text(
                      'Connection Status: $isConnected',
                    ),
                  );
                }
              },
            ),
          ],
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

    // After adding your certificates to the pubspec.yaml, you can use Security Context.

    // ByteData rootCA = await rootBundle.load('assets/certs/AmazonRootCA1.pem');
    // ByteData deviceCert = await rootBundle.load(
    //     'assets/certs/cac3309015bb5acd72c59e9c7adc8f5c96c0cb4ce67aec48898e847f63757707-certificate.pem.crt');
    // ByteData privateKey = await rootBundle.load(
    //     'assets/certs/cac3309015bb5acd72c59e9c7adc8f5c96c0cb4ce67aec48898e847f63757707-private.pem.key');

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

    print(
        '#########################################: Updates :  ${client.updates}');

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMess;

    print(
        '>>>>>>>>>>>>>>>>>>>>>>>>>Connection message>>>>>>>>>>>>>>>>>>>>: $connMess');

    //await client.connect();

    try {
      await client.connect();
    } catch (e) {
      print('>>>>>>>>>>>>>>>>>>>>>>>>>Exception>>>>>>>>>>>>>>>>>>>>: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to AWS Successfully!");
    } else {
      print("Connected to AWS was not Successfully!");
      return false;
    }

    final topic = topicController.text;
    // const topic = 'ESP32SIM800L-Test/ESP32SIM800L-Test-policy';
    client.subscribe(topic, MqttQos.atMostOnce);

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
    print('Ping response client callback invoked');
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

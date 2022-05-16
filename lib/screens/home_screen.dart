import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';

// final mqttReceivedMessages = snapshot.data as List<MqttReceivedMessage<MqttMessage?>>?;
// final recMess = mqttReceivedMessages![0].payload as MqttPublishMessage;

const awsDataEndpoint = 'abzdpvuwkaq5j-ats.iot.ap-southeast-1.amazonaws.com';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MqttServerClient client =
  MqttServerClient(awsDataEndpoint, '');
  bool isConnected = false;
  String statusText = "Status Text";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _connect();
          },
          child: const Text('Connect'),
        ),
      ),
    );
  }

  _connect() async {

      ProgressDialog progressDialog = ProgressDialog(context,
          blur: 0,
          dialogTransitionType: DialogTransitionType.Shrink,
          dismissable: false);
      progressDialog.setLoadingWidget(const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.red),
      ));
      progressDialog
          .setMessage(const Text("Please Wait, Connecting to AWS IoT MQTT Broker"));
      progressDialog.setTitle(const Text("Connecting"));
      progressDialog.show();

      isConnected = await mqttConnect('ss-1994');
      progressDialog.dismiss();

  }

  _disconnect() {
    client.disconnect();
  }

  Future<bool> mqttConnect(String clientId) async {
    setStatus("Connecting MQTT Broker..........");

   // After adding your certificates to the pubspec.yaml, you can use Security Context.

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

    final MqttConnectMessage connMess =
    MqttConnectMessage().withClientIdentifier(clientId).startClean();
    client.connectionMessage = connMess;

   // await client.connect();




    try {
      await client.connect();
    } catch(e) {
      print('>>>>>>>>>>>>>>>>>>>>>>>>>Exception>>>>>>>>>>>>>>>>>>>>: $e');
      client.disconnect();
    }





    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to AWS Successfully!");
    } else {
      print("Connected to AWS was not Successfully!");
      return false;
    }

    const topic = 'ESP32SIM800L-Test/ESP32SIM800L-Test-policy';
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

}

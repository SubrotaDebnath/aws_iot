import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'dart:convert';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MqttServerClient client = MqttServerClient(Config.awsDataEndpoint, '');
  bool isConnected = false;
  bool isSubscribed = false;
  String statusText = "Status Text";
  String subTopic = '';
  String pubTopic = '';
  String pubReqMessage = '';
  String mess = '';

  final List<String> items = [
    'ESP32SIM800L-Test',
    'Your-Shop',
  ];
  String? selectedValue;

  // TextEditingController thingController =
  //     TextEditingController();
  TextEditingController payloadController = TextEditingController();
  TextEditingController topicController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      child: Scaffold(
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
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Text('Things: ${selectedValue.toString()}'),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 8,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2(
                                isExpanded: true,
                                hint: const Row(
                                  children: [
                                    Icon(
                                      Icons.list,
                                      size: 16,
                                      color: Colors.yellow,
                                    ),
                                    SizedBox(
                                      width: 4,
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Select Thing',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.yellow,
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
                                iconEnabledColor: Colors.yellow,
                                iconDisabledColor: Colors.grey,
                                buttonHeight: 50,
                                buttonWidth: MediaQuery.of(context).size.width*.9,
                                buttonPadding:
                                    const EdgeInsets.only(left: 14, right: 14),
                                buttonDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black26,
                                  ),
                                  color: Colors.redAccent,
                                ),
                                buttonElevation: 2,
                                itemHeight: 40,
                                itemPadding:
                                    const EdgeInsets.only(left: 14, right: 14),
                                dropdownMaxHeight: 200,
                                dropdownWidth:  MediaQuery.of(context).size.width*.9,
                                dropdownPadding: null,
                                dropdownDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.orange,
                                ),
                                dropdownElevation: 8,
                                scrollbarRadius: const Radius.circular(40),
                                scrollbarThickness: 6,
                                scrollbarAlwaysShow: true,
                                offset: const Offset(0, 0),
                              ),
                            ),
                          ),
                  ),
                  SizedBox(
                    child: isConnected
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                _disconnect();
                                setState(() {
                                  isSubscribed = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Disconnect'),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: ElevatedButton(
                              onPressed: () {
                                if (selectedValue != null &&
                                    selectedValue!.trim().isNotEmpty) {
                                  _connect();
                                } else {
                                  const snackBar = SnackBar(
                                    content: Text('Select a thing'),
                                    backgroundColor: Colors.green,
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: const Text('Connect'),
                            ),
                          ),
                  ),
                  SizedBox(
                    child: isConnected
                        ? SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  height: 8,
                                ),
                                const Divider(
                                  color: Colors.teal,
                                  thickness: 1,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TextFormField(
                                    controller: topicController,
                                    decoration: InputDecoration(
                                      suffixIcon: isSubscribed
                                          ? const Icon(
                                              Icons
                                                  .check_circle_outline_outlined,
                                              color: Colors.green,
                                            )
                                          : const Icon(
                                              Icons.cancel_outlined,
                                              color: Colors.red,
                                            ),
                                      suffixIconColor: isSubscribed
                                          ? Colors.green
                                          : Colors.red,
                                      border: InputBorder.none,
                                      hintText: 'Topic',
                                      labelText: 'Topic',
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      contentPadding: const EdgeInsets.only(
                                          left: 14.0, bottom: 6.0, top: 8.0),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.teal),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.grey),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (topicController.text
                                        .trim()
                                        .isNotEmpty) {
                                      subTopic =
                                          "${topicController.text.trim()}/pub";
                                      pubTopic =
                                          "${topicController.text.trim()}/sub";
                                      // final subRes = subscribe(topic: subTopic);
                                      context.loaderOverlay.show(
                                          widget: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: const Center(
                                          child: Text('Subscribing...'),
                                        ),
                                      ));
                                      final subRes = client.subscribe(
                                          subTopic, MqttQos.atMostOnce);

                                      if (subRes != null) {
                                        context.loaderOverlay.hide();
                                        setState(() {
                                          isSubscribed = true;
                                        });
                                      } else {
                                        context.loaderOverlay.hide();
                                        setState(() {
                                          isSubscribed = false;
                                        });
                                      }

                                      if (kDebugMode) {
                                        print(
                                          '\n........................Subscription Response: ${subRes.toString()}..........................\n');
                                      }
                                      // onPublishButtonPressed(
                                      //   topic: topicController.text,
                                      //   payload: topicController.text.trim(),
                                      // );
                                    } else {
                                      const snackBar = SnackBar(
                                        content: Text('Subscribe first.'),
                                        backgroundColor: Colors.teal,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal),
                                  child: const Text('Subscribe'),
                                ),
                                const SizedBox(
                                  height: 8,
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
                                        borderSide: const BorderSide(
                                            color: Colors.teal),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.grey),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (payloadController.text
                                        .trim()
                                        .isNotEmpty) {
                                      if (subTopic.trim().isNotEmpty) {
                                        onPublishButtonPressed(
                                          topic: pubTopic,
                                          payload:
                                              payloadController.text.trim(),
                                        );
                                      } else {
                                        const snackBar = SnackBar(
                                          content: Text('Subscribe first.'),
                                          backgroundColor: Colors.teal,
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);
                                      }
                                    } else {
                                      const snackBar = SnackBar(
                                        content:
                                            Text('Type some message first.'),
                                        backgroundColor: Colors.teal,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal),
                                  child: const Text('Publish'),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                const Divider(
                                  color: Colors.green,
                                  thickness: 1,
                                ),
                                GridView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 5,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8),
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        if (subTopic.trim().isNotEmpty) {
                                          onPublishButtonPressed(
                                            topic: pubTopic,
                                            payload: '{"wash_type": "Pause"}',
                                          );

                                          setState(() {
                                            mess = '';
                                            pubReqMessage =
                                            '{"wash_type": "Pause"}';
                                          });
                                        } else {
                                          const snackBar = SnackBar(
                                            content: Text('Subscribe first.'),
                                            backgroundColor: Colors.teal,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }


                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text('Pause/Play'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {

                                        if (subTopic.trim().isNotEmpty) {

                                          onPublishButtonPressed(
                                            topic: pubTopic,
                                            payload:
                                            '{"detailed_status": "detailed_status"}',
                                          );
                                          setState(() {
                                            mess = '';
                                            pubReqMessage =
                                            '{"detailed_status": "detailed_status"}';
                                          });
                                        } else {
                                          const snackBar = SnackBar(
                                            content: Text('Subscribe first.'),
                                            backgroundColor: Colors.teal,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }



                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text('Status Details'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {

                                        if (subTopic.trim().isNotEmpty) {
                                          onPublishButtonPressed(
                                            topic: pubTopic,
                                            payload: '{"status": "Status"}',
                                          );

                                          setState(() {
                                            mess = '';
                                            pubReqMessage =
                                            '{"status": "Status"}';
                                          });
                                        } else {
                                          const snackBar = SnackBar(
                                            content: Text('Subscribe first.'),
                                            backgroundColor: Colors.teal,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }


                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text('Check Status'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {


                                        if (subTopic.trim().isNotEmpty) {
                                          onPublishButtonPressed(
                                            topic: pubTopic,
                                            payload: '{"status": "Restart"}',
                                          );

                                          setState(() {
                                            mess = '';
                                            pubReqMessage =
                                            '{"status": "Restart"}';
                                          });
                                        } else {
                                          const snackBar = SnackBar(
                                            content: Text('Subscribe first.'),
                                            backgroundColor: Colors.teal,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }

                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text('Restart'),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                              ],
                            ),
                          )
                        : Container(),
                  ),
                  Container(
                    color: Colors.grey.shade300,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Request Message',
                              style:
                                  TextStyle(color: Colors.orange, fontSize: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              pubReqMessage,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 16),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Response Status',
                              style:
                                  TextStyle(color: Colors.orange, fontSize: 16),
                            ),
                          ),
                          StreamBuilder(
                            stream: client.updates,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final mqttReceivedMessages = snapshot.data
                                    as List<MqttReceivedMessage<MqttMessage?>>?;

                                final recMess = mqttReceivedMessages![0].payload
                                    as MqttPublishMessage;

                                mess =
                                    "${utf8.decode(recMess.payload.message).toString()}\n Updated At: ${DateTime.now().toString()}";

                                return isConnected
                                    ? Text(mess)
                                    : const Text('');
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 8),
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
                ],
              ),
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
      title: const Text('title'), message: null,
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

    String deviceId = await PlatformDeviceId.getDeviceId?? DateTime.now().toString();
    isConnected = await mqttConnect(deviceId);

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

    // final topic = thingController.text.trim();
    // const topic = 'ESP32SIM800L-Test/ESP32SIM800L-Test-policy';
    // client.subscribe(topic, MqttQos.atMostOnce);
    // client.subscribe('s', MqttQos.atMostOnce);
    // client.subscribe('ss', MqttQos.atMostOnce);
    // client.subscribe('sss', MqttQos.atMostOnce);

    return true;
  }

  void subscribe({required String topic}) {
    client.subscribe(topic, MqttQos.atMostOnce);
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

import 'dart:io';

import 'package:ditto_live/ditto_live.dart';
import 'package:ditto_live_example/dialog.dart';
import 'package:ditto_live_example/dql_builder.dart';
import 'package:ditto_live_example/task.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Online with Authentication Creds
const appID = "YOUR_APP_ID";

Future<void> main() async {
  runApp(const MaterialApp(home: DittoExample()));
}

class DittoExample extends StatefulWidget {
  const DittoExample({super.key});

  @override
  State<DittoExample> createState() => _DittoExampleState();
}

class _DittoExampleState extends State<DittoExample> {
  Ditto? _ditto;

  @override
  void initState() {
    super.initState();

    _initDitto();
  }

  Future<void> _initDitto() async {
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
      Permission.bluetoothScan
    ].request();

/**
 *  START - Example with Online with Authentication hitting custom Big Peer cloud
 */

    final authenticationHandler = AuthenticationHandler(
      authenticationRequired: (authenticator) {
        print("authenticating");
        authenticator.login(token: "manager01", provider: "replit-auth");
      },
      authenticationExpiringSoon: (authenticator, secondsRemaining) {
        print("Auth token expiring in $secondsRemaining seconds");
        authenticator.login(token: "manager01", provider: "replit-auth");
      },
    );

    final identity = await OnlineWithAuthenticationIdentity.create(
      appID: appID,
      authenticationHandler: authenticationHandler,
      customAuthUrl: "https://$appID.cloud-dev.ditto.live" // Custom Big Peer endpoint
      );

/**
 *  END - Example with Online Playground hitting cloud-dev & custom auth webhook
 */

    final dataDir = await getApplicationDocumentsDirectory();
    final persistenceDirectory = Directory("${dataDir.path}/ditto");
    await persistenceDirectory.create(recursive: true);

    final ditto = await Ditto.open(
      identity: identity,
      persistenceDirectory: persistenceDirectory,
    );

    // Using a custom transport config to specify the websocket endpoint of a custom Big Peer Endpoint
    final peerToPeer = PeerToPeer.all();
    final connect = Connect(webSocketUrls: {"wss://$appID.cloud-dev.ditto.live"});
    final transportConfig = TransportConfig(peerToPeer: peerToPeer, connect: connect);
    ditto.setTransportConfig(transportConfig);

    await ditto.startSync();

    setState(() => _ditto = ditto);
  }

  Future<void> _addTask() async {
    final task = await showAddTaskDialog(context);
    if (task == null) return;

    await _ditto!.store.execute(
      "INSERT INTO tasks DOCUMENTS (:task)",
      arguments: {"task": task.toJson()},
    );
  }

  Future<void> _clearTasks() async {
    await _ditto!.store.execute("EVICT FROM tasks WHERE true");
  }

  @override
  Widget build(BuildContext context) {
    final ditto = _ditto;

    if (ditto == null) return _loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ditto Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: "Clear",
            onPressed: _clearTasks,
          ),
        ],
      ),
      floatingActionButton: _fab,
      body: Column(
        children: [
          _portalInfo,
          const Divider(height: 1),
          Expanded(child: _tasksList),
        ],
      ),
    );
  }

  Widget get _loading => Scaffold(
        appBar: AppBar(title: const Text("Ditto Tasks")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center horizontally
            children: [
              const CircularProgressIndicator(),
              const Text("Ensure your AppID and Token are correct"),
              _portalInfo
            ],
          ),
        ),
      );

  Widget get _fab => FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add_task),
      );

  Widget get _portalInfo => const Column(children: [
        Text(
          "AppID: $appID",
          style: TextStyle(fontSize: 12),
        ),
        Text(
          "Online With Authentication",
          style: TextStyle(fontSize: 12),
        ),
      ]);

  Widget get _tasksList => DqlBuilder(
        ditto: _ditto!,
        query: "SELECT * FROM tasks WHERE deleted = false",
        builder: (context, response) {
          final tasks = response.items.map((r) => r.value).map(Task.fromJson);
          return ListView(
            children: tasks.map(_singleTask).toList(),
          );
        },
      );

  Widget _singleTask(Task task) => Dismissible(
        key: Key("${task.id}-${task.title}"),
        onDismissed: (direction) async {
          await _ditto!.store.execute(
            "UPDATE tasks SET deleted = true WHERE _id = '${task.id}'",
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Deleted Task ${task.title}")),
            );
          }
        },
        background: _dismissibleBackground(true),
        secondaryBackground: _dismissibleBackground(false),
        child: CheckboxListTile(
          title: Text(task.title),
          subtitle: Text(task.description),
          value: task.done,
          onChanged: (value) => _ditto!.store.execute(
            "UPDATE tasks SET done = $value WHERE _id = '${task.id}'",
          ),
        ),
      );

  Widget _dismissibleBackground(bool primary) => Container(
        color: Colors.red,
        child: Align(
          alignment: primary ? Alignment.centerLeft : Alignment.centerRight,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.delete),
          ),
        ),
      );
}

import 'dialog.dart';
import 'dql_builder.dart';
import 'task.dart';

import 'package:ditto_live/ditto_live.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = "caf9e870-d416-4b1c-9ab4-fb6e8319dd25";
const token = "cb639c76-5633-44dd-ad28-03a5a43f092e";

void main() => runApp(const MaterialApp(home: DittoExample()));

class DittoExample extends StatefulWidget {
  const DittoExample({super.key});

  @override
  State<DittoExample> createState() => _DittoExampleState();
}

class _DittoExampleState extends State<DittoExample> {
  Ditto? _ditto;
  var _syncing = true;

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

    final identity = await OnlinePlaygroundIdentity.create(
      appId: appId,
      token: token,
      baseUrl: "https://$appId.cloud.ditto.live",
    );
    final ditto = await Ditto.create(identity);
    await ditto.startSync();

    setState(() => _ditto = ditto);
  }

  Future<void> _addTask() async {
    final task = await showAddTaskDialog(context);
    if (task == null) return;

    await _ditto!.execute(
      "INSERT INTO tasks DOCUMENTS (:task)",
      queryArgs: {"task": task.toJson()},
    );
  }

  Future<void> _clearTasks() async {
    await _ditto!.execute("EVICT FROM tasks WHERE true");
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
          _syncTile,
          const Divider(height: 1),
          Expanded(child: _tasksList),
        ],
      ),
    );
  }

  Widget get _loading => Scaffold(
        appBar: AppBar(title: const Text("Ditto Tasks")),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );

  Widget get _fab => FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add_task),
      );

  Widget get _syncTile => SwitchListTile(
        title: const Text("Syncing"),
        value: _syncing,
        onChanged: (value) async {
          if (value) {
            await _ditto!.startSync();
          } else {
            await _ditto!.stopSync();
          }

          setState(() => _syncing = value);
        },
      );

  Widget get _tasksList => DqlBuilder(
        ditto: _ditto!,
        query: "SELECT * FROM tasks WHERE deleted = false",
        builder: (context, response) {
          final tasks = response.items.map(Task.fromJson);
          return ListView(
            children: tasks.map(_singleTask).toList(),
          );
        },
      );

  Widget _singleTask(Task task) => Dismissible(
        key: Key("${task.id}-${task.title}"),
        onDismissed: (direction) async {
          await _ditto!.execute(
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
          onChanged: (value) => _ditto!.execute(
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

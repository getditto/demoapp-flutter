import 'package:ditto_live/ditto_live.dart';
import 'package:flutter/material.dart';

class DqlBuilder extends StatefulWidget {
  final Ditto ditto;
  final String query;
  final Map<String, dynamic>? queryArgs;
  final Widget Function(BuildContext, QueryResult) builder;
  final Widget? loading;

  const DqlBuilder({
    super.key,
    required this.ditto,
    required this.query,
    this.queryArgs,
    required this.builder,
    this.loading,
  });

  @override
  State<DqlBuilder> createState() => _DqlBuilderState();
}

class _DqlBuilderState extends State<DqlBuilder> {
  StoreObserver? _observer;
  SyncSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    _observer = widget.ditto.store
        .registerObserver(
          widget.query,
          arguments: widget.queryArgs ?? {},
        );
    _subscription = widget.ditto.sync
        .registerSubscription(
          widget.query,
          arguments: widget.queryArgs ?? {},
        );
  }

  @override
  void didUpdateWidget(covariant DqlBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isSame = widget.query == oldWidget.query &&
        widget.queryArgs == oldWidget.queryArgs;

    if (!isSame) {
      _observer?.cancel();
      _subscription?.cancel();

      final observer = widget.ditto.store
          .registerObserver(
            widget.query,
            arguments: widget.queryArgs ?? {},
          );

      final subscription = widget.ditto.sync
          .registerSubscription(
            widget.query,
            arguments: widget.queryArgs ?? {},
          );
      setState(() {
        _observer = observer;
        _subscription = subscription;
      });
    }
  }

  @override
  void dispose() {
    _observer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.loading ?? _defaultLoading;
    final stream = _observer?.changes;
    if (stream == null) return placeholder;

    return StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          final response = snapshot.data;
          if (response == null) return widget.loading ?? _defaultLoading;
          return widget.builder(context, response);
        });
  }
}

const _defaultLoading = Center(child: CircularProgressIndicator());

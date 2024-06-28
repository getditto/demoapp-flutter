import 'package:ditto_live/ditto_live.dart';
import 'package:flutter/material.dart';

class DqlBuilder extends StatefulWidget {
  final Ditto ditto;
  final String query;
  final Map<String, dynamic>? queryArgs;
  final Widget Function(BuildContext, DittoQueryResult) builder;
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
  Observer? _observer;
  Subscription? _subscription;

  @override
  void initState() {
    super.initState();

    widget.ditto
        .registerObserver(
          widget.query,
          queryArgs: widget.queryArgs ?? {},
        )
        .then((observer) => setState(() => _observer = observer));

    widget.ditto
        .registerSubscription(
          widget.query,
          queryArgs: widget.queryArgs ?? {},
        )
        .then((subscription) => setState(() => _subscription = subscription));
  }

  @override
  void didUpdateWidget(covariant DqlBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isSame = widget.query == oldWidget.query &&
        widget.queryArgs == oldWidget.queryArgs;

    if (!isSame) {
      _observer?.cancel();
      _subscription?.cancel();

      widget.ditto
          .registerObserver(
            widget.query,
            queryArgs: widget.queryArgs ?? {},
          )
          .then((observer) => setState(() => _observer = observer));

      widget.ditto
          .registerSubscription(
            widget.query,
            queryArgs: widget.queryArgs ?? {},
          )
          .then((subscription) => setState(() => _subscription = subscription));
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
    final stream = _observer?.results;
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

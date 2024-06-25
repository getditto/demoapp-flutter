import 'package:ditto_live/ditto_live.dart';
import 'package:flutter/material.dart';

class DqlBuilder extends StatefulWidget {
  final Ditto ditto;
  final String query;
  final Map<String, dynamic>? queryArgs;
  final Widget Function(BuildContext, DqlResponse) builder;
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
  late Observer _observer;

  @override
  void initState() {
    super.initState();

    final newObserver = widget.ditto.observe(
      widget.query,
      queryArgs: widget.queryArgs ?? {},
    );

    setState(() => _observer = newObserver);
  }

  @override
  void didUpdateWidget(covariant DqlBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isSame = widget.query == oldWidget.query &&
        widget.queryArgs == oldWidget.queryArgs;

    if (!isSame) {
      _observer.dispose();

      final newObserver = widget.ditto.observe(
        widget.query,
        queryArgs: widget.queryArgs ?? {},
      );

      setState(() => _observer = newObserver);
    }
  }

  @override
  void dispose() {
    _observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(stream: _observer.responses, builder: (context, snapshot) {
      final response = snapshot.data;
      if (response == null) return widget.loading ?? _defaultLoading;
      return widget.builder(context, response);
    });
  }
}

const _defaultLoading = Center(child: CircularProgressIndicator());

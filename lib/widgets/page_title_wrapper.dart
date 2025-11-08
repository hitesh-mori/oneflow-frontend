import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../services/storage_service.dart';
import '../main.dart';

class PageTitleWrapper extends StatefulWidget {
  final Widget child;
  final String title;

  const PageTitleWrapper({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<PageTitleWrapper> createState() => _PageTitleWrapperState();
}

class _PageTitleWrapperState extends State<PageTitleWrapper> {
  @override
  void initState() {
    super.initState();
    _setTitle();
  }

  @override
  void didUpdateWidget(PageTitleWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _setTitle();
    }
  }

  Future<void> _setTitle() async {
    // Update global variable
    pageTitle = widget.title;

    // Set title immediately
    html.document.title = widget.title;

    // Store in SharedPreferences so it persists on refresh
    await StorageService.savePageTitle(widget.title);

    // Set again after frame to ensure it persists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      html.document.title = widget.title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

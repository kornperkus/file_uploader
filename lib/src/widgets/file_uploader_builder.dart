import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';

import '../file_uploader.dart';

class FileUploaderBuilder extends StatefulWidget {
  final FileUploadController controller;
  final Widget Function(BuildContext, FileUploadState, Widget?) builder;

  const FileUploaderBuilder({
    Key? key,
    required this.controller,
    required this.builder,
  }) : super(key: key);

  @override
  State<FileUploaderBuilder> createState() => _FileUploaderBuilderState();
}

class _FileUploaderBuilderState extends State<FileUploaderBuilder> {
  @override
  Widget build(BuildContext context) {
    return StateNotifierBuilder<FileUploadState>(
      stateNotifier: widget.controller,
      builder: widget.builder,
    );
  }
}

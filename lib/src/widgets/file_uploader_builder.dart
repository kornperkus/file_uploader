import 'package:flutter/material.dart';

import '../controller/file_uploader_controller.dart';

class FileUploaderBuilder extends StatefulWidget {
  final FileUploadController controller;
  final Widget Function(BuildContext, FileUploadState, Widget?) builder;
  final Widget? child;

  const FileUploaderBuilder({
    Key? key,
    required this.controller,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  State<FileUploaderBuilder> createState() => _FileUploaderBuilderState();
}

class _FileUploaderBuilderState extends State<FileUploaderBuilder> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FileUploadState>(
      valueListenable: widget.controller,
      builder: widget.builder,
      child: widget.child,
    );
  }
}

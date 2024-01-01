import 'package:flutter/material.dart';
import 'package:file_uploader/l10n/flutter_gen/localizations.dart';
import 'package:file_uploader/l10n/flutter_gen/localizations_en.dart';

import '../file_upload_info.dart';
import '../file_uploader.dart';

class UploadProgressSnackBar {
  ScaffoldFeatureController? _snackBarController;

  void showSnackBar({
    required BuildContext context,
    required FileUploadController controller,
    UploadProgressSnackBarOptions options =
        const UploadProgressSnackBarOptions(),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    scaffoldMessenger?.hideCurrentSnackBar();
    _snackBarController = scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: _SnackBarContent(
          controller: controller,
          options: options,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: options.backgroundColor,
        dismissDirection: DismissDirection.none,
        padding: EdgeInsets.zero,
        duration: const Duration(hours: 1),
      ),
    );
  }

  void hideSnackBar() {
    _snackBarController?.close();
  }
}

class _SnackBarContent extends StatefulWidget {
  final FileUploadController controller;
  final UploadProgressSnackBarOptions options;

  const _SnackBarContent({
    Key? key,
    required this.controller,
    required this.options,
  }) : super(key: key);

  @override
  State<_SnackBarContent> createState() => _SnackBarContentState();
}

class _SnackBarContentState extends State<_SnackBarContent> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final localizations =
        FileUploaderLocalizations.of(context) ?? FileUploaderLocalizationsEn();

    return ValueListenableBuilder<FileUploadState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  if (state.isUploaded)
                    const Icon(
                      Icons.done,
                      color: Colors.blue,
                      size: 30,
                    )
                  else
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      localizations.filesUploaded(
                        state.uploadedCount,
                        state.uploadingCount,
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      if (expanded) {
                        setState(() {
                          expanded = false;
                        });
                      } else {
                        setState(() {
                          expanded = true;
                        });
                      }
                    },
                    icon: expanded
                        ? widget.options.expandedMoreIcon
                        : widget.options.expandLessIcon,
                  ),
                  IconButton(
                    onPressed: state.isUploaded
                        ? () {
                            widget.controller.closeSnackBar();
                          }
                        : null,
                    icon: widget.options.closeIcon,
                  ),
                ],
              ),
              if (state.isUploaded && state.hasError)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.someFileFailToUpload,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => widget.controller.retryUpload(
                          context: context,
                          files: widget.controller.getErrorFiles(),
                        ),
                        child: Text(
                          localizations.retry,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (expanded)
                Column(
                  children: [
                    Divider(
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: state.uploading.length,
                        itemBuilder: (context, index) => _ListItem(
                          fileUploadInfo: state.uploading[index],
                          options: widget.options,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ListItem extends StatelessWidget {
  final FileUploadInfo fileUploadInfo;
  final UploadProgressSnackBarOptions options;

  const _ListItem({
    required this.fileUploadInfo,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        fileUploadInfo.name ?? 'untitled',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: fileUploadInfo.isUploaded
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(
                value: fileUploadInfo.progress / 100,
                color: Theme.of(context).primaryColor,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
      leading: fileUploadInfo.isUploaded
          ? fileUploadInfo.error != null
              ? options.uploadFailedIcon
              : options.uploadSuccessIcon
          : null,
    );
  }
}

class UploadProgressSnackBarOptions {
  final Color backgroundColor;
  final Widget expandedMoreIcon;
  final Widget expandLessIcon;
  final Widget closeIcon;
  final Widget uploadSuccessIcon;
  final Widget uploadFailedIcon;

  const UploadProgressSnackBarOptions({
    this.backgroundColor = Colors.white,
    this.expandedMoreIcon = const Icon(Icons.expand_more),
    this.expandLessIcon = const Icon(Icons.expand_less),
    this.closeIcon = const Icon(Icons.close),
    this.uploadSuccessIcon = const Icon(Icons.done, color: Colors.green),
    this.uploadFailedIcon = const Icon(Icons.close, color: Colors.red),
  });
}

import 'package:flutter/material.dart';
import 'package:file_uploader/l10n/flutter_gen/localizations.dart';
import 'package:file_uploader/l10n/flutter_gen/localizations_en.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';

import '../controller/shipment_image_upload_controller.dart';
import '../model/file_upload_info.dart';
import '../model/file_upload_status.dart';

class SnackBarContent extends StatefulWidget {
  final ShipmentImageUploadController controller;
  final UploadProgressSnackBarOptions options;

  const SnackBarContent({
    Key? key,
    required this.controller,
    required this.options,
  }) : super(key: key);

  @override
  State<SnackBarContent> createState() => _SnackBarContentState();
}

class _SnackBarContentState extends State<SnackBarContent> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final localizations =
        FileUploaderLocalizations.of(context) ?? FileUploaderLocalizationsEn();

    return StateNotifierBuilder<ShipmentImageUploadState>(
      stateNotifier: widget.controller,
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  if (state.isUploadInProgress)
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  else
                    const Icon(
                      Icons.done,
                      color: Colors.blue,
                      size: 30,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      localizations.filesUploaded(
                        state.uploadingSuccessCount,
                        state.uploadingTotalCount,
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
                    onPressed: state.isUploadIdle
                        ? () => widget.controller.hideSnackBar()
                        : null,
                    icon: widget.options.closeIcon,
                  ),
                ],
              ),
              if (state.isUploadIdle && state.hasError)
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
                        onTap: () => widget.controller.retryUploadImages(
                          images: state.errorImages,
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
                        itemCount: state.uploadingImages.length,
                        itemBuilder: (context, index) => _ListItem(
                          fileUploadInfo: state.uploadingImages[index],
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
      subtitle: fileUploadInfo.status is FileUploadInprogress
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(
                value: (fileUploadInfo.status as FileUploadInprogress).progress,
                color: Theme.of(context).primaryColor,
                backgroundColor: Colors.grey.shade300,
              ),
            )
          : null,
      leading: fileUploadInfo.status is FileUploadSuccess
          ? options.uploadSuccessIcon
          : fileUploadInfo.status is FileUploadFailure
              ? options.uploadFailedIcon
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

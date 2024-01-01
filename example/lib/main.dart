import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_uploader/file_uploader.dart';
import 'package:file_uploader/l10n/flutter_gen/localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FileUploaderLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('th'),
      ],
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final FileUploadController fileUploadController;

  @override
  void initState() {
    super.initState();
    fileUploadController = FileUploadController(
      // progressSnackBarOptions: const ProgressSnackBarOptions(
      //   uploadSuccessIcon: Icon(Icons.done, color: Colors.green),
      // ),
      uploadFileTask: (uploadFile, uploadProgress) async {
        int progress = 0;
        final rand = Random();

        while (progress < 100) {
          await Future.delayed(Duration(milliseconds: rand.nextInt(1000)));
          progress = progress + 10;
          uploadProgress(id: uploadFile.id, progress: progress);
        }

        return null;
      },
      deleteFileTask: (file) async {
        await Future.delayed(const Duration(seconds: 1));
      },
    );

    _addUploadedFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          'Demo Page',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: FileUploaderBuilder(
        controller: fileUploadController,
        builder: (context, state, _) {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3),
            itemCount: state.files.length,
            itemBuilder: (context, index) {
              final item = state.files[index];
              return Container(
                margin: const EdgeInsets.all(8),
                width: 100,
                height: 100,
                color: Colors.grey.shade100,
                child: UploadImagePreview(
                  fileUploadInfo: state.files[index],
                  onRetryUploadPressed: () => fileUploadController
                      .retryUpload(context: context, files: [item]),
                  onDeletedPressed: () => fileUploadController.delete(item.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final files = await _getMockFiles();

          if (!mounted) return;
          fileUploadController.upload(
            context: context,
            files: files,
          );
        },
      ),
    );
  }

  void _addUploadedFiles() async {
    fileUploadController.addUploadedFiles(
      fileUrls: [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/1600px-Image_created_with_a_mobile_phone.png'
      ],
    );
  }

  Future<List<File>> _getMockFiles() async {
    try {
      final directory = await getTemporaryDirectory();

      List<File> files = [];

      for (int i = 1; i <= 5; i++) {
        final fileByteData =
            await rootBundle.load('assets/images/image-$i.jpg');
        final filepath = path.join(directory.path, 'image-$i.jpg');
        final imgFile = File(filepath);
        imgFile.writeAsBytes(fileByteData.buffer.asInt8List());
        files.add(imgFile);
      }
      return files;
    } catch (e) {
      return [];
    }
  }
}

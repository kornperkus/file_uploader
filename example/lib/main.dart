import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_uploader/file_uploader.dart';
import 'package:file_uploader/l10n/flutter_gen/localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final kScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: kScaffoldMessengerKey,
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
      home: const IntroPage(),
    );
  }
}

class IntroPage extends StatelessWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IconButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MyHomePage()));
          },
          icon: const Icon(Icons.upload),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with AfterLayoutMixin {
  late final ShipmentImageUploadController _shipmentImageUploadController;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _shipmentImageUploadController = ShipmentImageUploadController(
      scaffoldMessengerKey: kScaffoldMessengerKey,
    );
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _addUploadedFiles(ImageGroup.product);
    _addUploadedFiles(ImageGroup.document);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          'Demo Page',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            icon: const Icon(
              Icons.close,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: StateNotifierBuilder<ShipmentImageUploadState>(
        stateNotifier: _shipmentImageUploadController,
        builder: (context, state, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red,
                  child: Row(
                    children: [
                      const Text('Product'),
                      IconButton(
                        onPressed: () async {
                          final files = await _getMockFiles();

                          if (!mounted) return;
                          _shipmentImageUploadController.uploadImages(
                            imageFiles: files,
                            imageGroup: ImageGroup.product,
                          );
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
              SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: state.productImages.length,
                itemBuilder: (context, index) {
                  final item = state.productImages[index];
                  return Container(
                    margin: const EdgeInsets.all(8),
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade100,
                    child: UploadImagePreview(
                      fileUploadInfo: item,
                      onRetryUploadPressed: () => _shipmentImageUploadController
                          .retryUploadImages(images: [item]),
                      onDeletedPressed: () =>
                          _shipmentImageUploadController.deleteImage(item),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red,
                  child: Row(
                    children: [
                      const Text('Document'),
                      IconButton(
                        onPressed: () async {
                          final files = await _getMockFiles();

                          if (!mounted) return;
                          _shipmentImageUploadController.uploadImages(
                            imageFiles: files,
                            imageGroup: ImageGroup.document,
                          );
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
              SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: state.docImages.length,
                itemBuilder: (context, index) {
                  final item = state.docImages[index];
                  return Container(
                    margin: const EdgeInsets.all(8),
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade100,
                    child: UploadImagePreview(
                      fileUploadInfo: item,
                      onRetryUploadPressed: () => _shipmentImageUploadController
                          .retryUploadImages(images: [item]),
                      onDeletedPressed: () =>
                          _shipmentImageUploadController.deleteImage(item),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red,
                  child: Row(
                    children: [
                      const Text('Cover'),
                      IconButton(
                        onPressed: () async {
                          final files = await _getMockFiles();

                          if (!mounted) return;
                          _shipmentImageUploadController.uploadImages(
                            imageFiles: files,
                            imageGroup: ImageGroup.cover,
                          );
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
              SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: state.coverImages.length,
                itemBuilder: (context, index) {
                  final item = state.coverImages[index];
                  return Container(
                    margin: const EdgeInsets.all(8),
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade100,
                    child: UploadImagePreview(
                      fileUploadInfo: item,
                      onRetryUploadPressed: () => _shipmentImageUploadController
                          .retryUploadImages(images: [item]),
                      onDeletedPressed: () =>
                          _shipmentImageUploadController.deleteImage(item),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _addUploadedFiles(ImageGroup imageGroup) async {
    _shipmentImageUploadController.addUploadedImages(
      imageDataList: [
        {
          'id': _uuid.v4(),
          'url':
              'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/1600px-Image_created_with_a_mobile_phone.png'
        },
      ],
      imageGroup: imageGroup,
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

  @override
  void dispose() {
    _shipmentImageUploadController.dispose();
    super.dispose();
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewPage extends StatefulWidget {
  final File file;
  const PdfViewPage({
    super.key,
    required this.file,
  });

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  late PDFViewController controller;
  int pages = 0;
  int indexPage = 0;
  @override
  Widget build(BuildContext context) {
    final path = widget.file.path;
    final file = basename(path);
    final text = '${indexPage + 1} of $pages';
    return RepaintBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(file), actions: [
          pages >= 2 ? switchPages(text) : Text(""),
          IconButton(
            onPressed: () async {
              final box = context.findRenderObject() as RenderBox?;
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              const path = "assets/documents.pdf";
              final data = await rootBundle.load(path);
              final buffer = data.buffer;
              final shareResult = await Share.shareXFiles(
                [
                  XFile.fromData(
                    buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
                    name: 'documents.pdf',
                    mimeType: 'application/pdf',
                  ),
                ],
                sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
              );
              scaffoldMessenger.showSnackBar(
                getResultSnackBar(shareResult),
              );
            },
            icon: const Icon(Icons.share),
          ),
        ]),
        body: PDFView(
          pageFling: true,
          swipeHorizontal: true,
          fitPolicy: FitPolicy.BOTH,
          filePath: path,
          onRender: (pages) => setState(() => this.pages = pages!),
          onViewCreated: (controller) =>
              setState(() => this.controller = controller),
          onPageChanged: (indexPage, _) =>
              setState(() => this.indexPage = indexPage!),
        ),
      ),
    );
  }

  Widget switchPages(String text) {
    return Row(
      children: [
        Center(child: Text(text)),
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () {
            final page = indexPage == 0 ? pages : indexPage - 1;
            controller.setPage(page);
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 32),
          onPressed: () {
            final page = indexPage == pages - 1 ? 0 : indexPage + 1;
            controller.setPage(page);
          },
        ),
      ],
    );
  }

  SnackBar getResultSnackBar(ShareResult result) {
    return SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Share result: ${result.status}"),
          if (result.status == ShareResultStatus.success)
            Text("Shared to: ${result.raw}")
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:dart_openai/dart_openai.dart';
import 'dart:typed_data';

class AISummaryPage extends StatefulWidget {
  const AISummaryPage({super.key});

  @override
  State<AISummaryPage> createState() => _AISummaryPageState();
}

class _AISummaryPageState extends State<AISummaryPage> {
  String _summary = "Upload a lecture PDF to generate a summary.";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: Replace with your actual key
    OpenAI.apiKey = "OpenAI.apiKey = "YOUR_OPENAI_API_KEY";"; 
  }

  Future<void> _processPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
        _summary = "Reading document...";
      });

      try {
        Uint8List bytes = result.files.first.bytes!;
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        int endPage = document.pages.count > 5 ? 5 : document.pages.count;
        String fullText = PdfTextExtractor(document).extractText(
          startPageIndex: 0, 
          endPageIndex: endPage - 1
        );
        document.dispose();

        // Updated for dart_openai 5.1.0
        OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
          model: "gpt-4o-mini",
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  "You are an NTHU student assistant. Summarize this academic PDF into clear bullet points.",
                ),
              ],
              role: OpenAIChatMessageRole.system,
            ),
            OpenAIChatCompletionChoiceMessageModel(
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(fullText),
              ],
              role: OpenAIChatMessageRole.user,
            ),
          ],
        );

        setState(() {
          _summary = chatCompletion.choices.first.message.content?.first.text ?? "No summary found.";
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _summary = "Error: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Study Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _processPdf,
              icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.upload_file),
              label: Text(_isLoading ? "Summarizing..." : "Upload PDF"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(_summary, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
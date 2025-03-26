import 'package:asmolg/Constant/ApiConstant.dart';
import 'package:asmolg/Pdf_Viewer/OthefWidgets/Beta_lable.dart';
import 'package:asmolg/Pdf_Viewer/Summerized_Widgets/SummarizedPage.dart';
import 'package:asmolg/Provider/offline-online_status.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'Translate_Widgets/translation_dialog.dart';
import 'package:permission_handler/permission_handler.dart';


class FileViewerPage extends StatefulWidget {
  final String fileUrl;

  const FileViewerPage({Key? key, required this.fileUrl}) : super(key: key);

  @override
  _FileViewerPageState createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> with WidgetsBindingObserver {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey<ExpandableFabState> _fabKey = GlobalKey();
  late OnDeviceTranslator _translator;
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();

  bool _isTranslationModelReady = false;
  String _summaryText = ""; // Holds the summarized text
  String _translatedText = ""; // Holds the translated text
  String _selectedLanguage = "Choose a language"; // Default language display
  String _previousLanguage = ""; // To track if language changes
  bool _isLoading = false; // Shows loading status
  final Map<String, TranslateLanguage> _languages = {
    'Hindi': TranslateLanguage.hindi,
    'Bengali': TranslateLanguage.bengali,
    'Tamil': TranslateLanguage.tamil,
    'Telugu': TranslateLanguage.telugu,
    'Marathi': TranslateLanguage.marathi,
  };

  late final GenerativeModel model;

  @override
  void initState() {
    super.initState();
    _downloadTranslationModels();
    _requestStoragePermission();
    model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: GEMINI_API_KEY,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _downloadTranslationModels() async {
    try {
      for (var language in _languages.values) {
        if (!await _modelManager.isModelDownloaded(language.bcpCode)) {
          await _modelManager.downloadModel(language.bcpCode);
        }
      }

      setState(() {
        _isTranslationModelReady = true;
      });
    } catch (e) {
      debugPrint("Error downloading translation models: $e");
    }
  }

  Future<void> _requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      // Storage permission granted
      _downloadTranslationModels();
    } else if (await Permission.manageExternalStorage.request().isGranted) {
      // Manage external storage permission granted
      _downloadTranslationModels();
    } else if (await Permission.storage.isPermanentlyDenied) {
      // Permission permanently denied, redirect to settings
      openAppSettings();
    }
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _translator.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<String>(
          value: _selectedLanguage,
          items: ["Choose a language", ..._languages.keys]
              .map((language) => DropdownMenuItem(
            value: language,
            child: Text(language),
          ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                if (_selectedLanguage != value) {
                  _translatedText = ""; // Clear previous translation if language changes
                  _previousLanguage = value; // Track new language
                }
                _selectedLanguage = value;
              });
            }
          },
          underline: Container(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: OfflineBanner(),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.fileUrl,
            key: _pdfViewerKey,
          ),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _fabKey,
        distance: 80.0,
        type: ExpandableFabType.up,
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.black.withOpacity(0.5),
          blur: 5,
        ),
        children: [
          FloatingActionButton.extended(
            heroTag: "translate",
            onPressed: () {
              _fabKey.currentState?.toggle(); // Close the FAB
              _onTranslateButtonPressed();
            },
            label: const Row(
              children: [
                Text("Translate"),
                SizedBox(width: 5),
                BetaLabel(),
              ],
            ),
            icon: const Icon(Icons.translate),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          FloatingActionButton.extended(
            heroTag: "summarize",
            onPressed: () {
              _fabKey.currentState?.toggle(); // Close the FAB
              _onSummarizeButtonPressed();
            },
            label: const Row(
              children: [
                Text("Summarize"),
                SizedBox(width: 5),
                BetaLabel(),
              ],
            ),
            icon: const Icon(Icons.summarize),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  void _onTranslateButtonPressed() {
    if (_selectedLanguage == "Choose a language") {
      _showFlutterToast("Please select a language first.");
      return;
    }

    if (_previousLanguage != _selectedLanguage) {
      _translatedText = ""; // Clear previous translation
    }

    setState(() {
      _previousLanguage = _selectedLanguage;
      _isLoading = true; // Show the progress indicator
    });

    // Start the translation
    _translateText(widget.fileUrl, _languages[_selectedLanguage]!);
  }

  Future<void> _translateText(String fileUrl, TranslateLanguage targetLanguage) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final Uint8List pdfBytes = response.bodyBytes;

        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        final PdfTextExtractor extractor = PdfTextExtractor(document);

        String allText = "";
        for (int i = 0; i < document.pages.count; i++) {
          allText += extractor.extractText(startPageIndex: i, endPageIndex: i) + "\n";
        }

        document.dispose();

        // Initialize the translator
        _translator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: targetLanguage,
        );

        String translated = await _translator.translateText(allText);

        setState(() {
          _translatedText = translated;
          _isLoading = false; // Hide the progress indicator
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TranslationDialog(
              translatedText: _translatedText,
              selectedLanguage: _selectedLanguage,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing PDF: $e');
      setState(() {
        _isLoading = false; // Hide the progress indicator
      });
    }
  }

  void _onSummarizeButtonPressed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Fetch the PDF file
      final httpResponse = await http.get(Uri.parse(widget.fileUrl)); // Rename to `httpResponse`
      if (httpResponse.statusCode == 200) {
        final Uint8List pdfBytes = httpResponse.bodyBytes;

        // Step 2: Extract text from the PDF
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        final PdfTextExtractor extractor = PdfTextExtractor(document);

        String allText = "";
        for (int i = 0; i < document.pages.count; i++) {
          allText += extractor.extractText(startPageIndex: i, endPageIndex: i) + "\n";
        }
        document.dispose();

        // Step 3: Summarize the extracted text
        final content = [Content.text(allText)];
        final generatedResponse = await model.generateContent(content); // Rename to `generatedResponse`

        setState(() {
          _summaryText = generatedResponse.text ?? "No summary available.";
          _isLoading = false;
        });

        // Navigate to the summary page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SummaryPage(
              summaryText: _summaryText,          // Pass the Gemini API model
            ),
          ),
        );

      }
    } catch (e) {
      debugPrint('Error during summarization: $e');
      setState(() {
        _isLoading = false;
      });
      _showFlutterToast("Failed to summarize the document.");
    }
  }

  void _showFlutterToast(String message) {
    FToast fToast = FToast();
    fToast.init(context);

    final double screenWidth = MediaQuery.of(context).size.width;

    fToast.showToast(
      child: Container(
        width: screenWidth * 0.9, // Set width to 90% of the screen
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.black,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12.0),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 3),
    );
  }
}


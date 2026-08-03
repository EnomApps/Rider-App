import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';

/// A file the rider chose, already in memory and ready to upload.
///
/// Bytes rather than a path: the multipart request has to be replayable so it
/// can survive a token refresh, and on Android a gallery pick is a content URI
/// that a plain `File` cannot always reopen later.
@immutable
class PickedDocument {
  const PickedDocument({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;

  int get sizeBytes => bytes.length;

  bool get isTooLarge => sizeBytes > AppConfig.maxDocumentBytes;
}

/// Why picking a file did not produce one.
enum PickFailure {
  /// The rider backed out of the camera or the file browser. Not an error —
  /// the UI stays silent for this one.
  cancelled,

  /// Over the API's 5 MB ceiling.
  tooLarge,

  /// Not a JPG, PNG or PDF.
  unsupportedType,

  /// The OS refused, most often because camera or photo permission was denied
  /// permanently.
  denied,
}

@immutable
class PickResult {
  const PickResult.success(this.document) : failure = null;

  const PickResult.failed(this.failure) : document = null;

  final PickedDocument? document;
  final PickFailure? failure;

  bool get isSuccess => document != null;
}

/// Wraps the two pickers behind one API.
///
/// Kept as a class with an interface so the wizard can be widget-tested
/// without a platform channel — `image_picker` and `file_picker` both throw on
/// a bare test binding.
abstract class DocumentPicker {
  /// Opens the camera. [source] is the gallery when the rider chooses that
  /// instead.
  Future<PickResult> pickImage(ImageSource source);

  /// Opens the system file browser, filtered to the accepted extensions.
  Future<PickResult> pickFile();
}

class PlatformDocumentPicker implements DocumentPicker {
  PlatformDocumentPicker({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Downscaled on the way in. A modern phone camera produces 8-12 MB frames,
  /// which the API rejects outright at 5 MB; 1600px on the long edge keeps a
  /// licence number comfortably legible while landing well inside the limit,
  /// and it is far kinder to a rider's data plan.
  static const double _maxDimension = 1600;
  static const int _jpegQuality = 82;

  @override
  Future<PickResult> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _jpegQuality,
      );
      if (picked == null) return const PickResult.failed(PickFailure.cancelled);

      final Uint8List bytes = await picked.readAsBytes();
      return _validate(
        bytes: bytes,
        filename: _ensureExtension(picked.name, 'jpg'),
        mimeType: picked.mimeType ?? _mimeFromName(picked.name),
      );
    } catch (_) {
      // image_picker throws a PlatformException for a permanently denied
      // permission and for a camera that is unavailable. Neither is worth
      // distinguishing to the rider — both mean "we could not open it".
      return const PickResult.failed(PickFailure.denied);
    }
  }

  @override
  Future<PickResult> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConfig.allowedDocumentExtensions,
        // Required: without it file_picker returns a path only, and a content
        // URI on Android is not reliably reopenable later.
        withData: true,
      );

      final PlatformFile? file = result?.files.single;
      final Uint8List? bytes = file?.bytes;
      if (file == null || bytes == null) {
        return const PickResult.failed(PickFailure.cancelled);
      }

      return _validate(
        bytes: bytes,
        filename: file.name,
        mimeType: _mimeFromName(file.name),
      );
    } catch (_) {
      return const PickResult.failed(PickFailure.denied);
    }
  }

  static PickResult _validate({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) {
    final String extension = _extensionOf(filename);
    if (!AppConfig.allowedDocumentExtensions.contains(extension)) {
      return const PickResult.failed(PickFailure.unsupportedType);
    }

    final PickedDocument document = PickedDocument(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
    if (document.isTooLarge) {
      return const PickResult.failed(PickFailure.tooLarge);
    }
    return PickResult.success(document);
  }

  static String _extensionOf(String filename) {
    final int dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }

  /// A camera capture on some Android OEM builds comes back with no extension
  /// at all, which would then fail the allow-list check for a file that is
  /// perfectly valid.
  static String _ensureExtension(String filename, String fallback) {
    return _extensionOf(filename).isEmpty ? '$filename.$fallback' : filename;
  }

  static String _mimeFromName(String filename) {
    switch (_extensionOf(filename)) {
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}

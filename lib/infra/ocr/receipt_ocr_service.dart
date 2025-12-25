import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'receipt_parser.dart';

class ReceiptOcrService {
  ReceiptOcrService({
    ImagePicker? imagePicker,
    ImageCropper? imageCropper,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _imageCropper = imageCropper ?? ImageCropper();

  final ImagePicker _imagePicker;
  final ImageCropper _imageCropper;
  final ReceiptParser _parser = ReceiptParser();

  Future<ReceiptParseResult?> captureAndParse() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) {
      return null;
    }

    final cropped = await _imageCropper.cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop receipt',
          hideBottomControls: false,
        ),
      ],
    );
    if (cropped == null) {
      return null;
    }

    final recognizer = TextRecognizer();
    final inputImage = InputImage.fromFilePath(cropped.path);
    final recognizedText = await recognizer.processImage(inputImage);
    await recognizer.close();

    return _parser.parse(recognizedText.text);
  }

  Future<File?> captureOnly() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    return image == null ? null : File(image.path);
  }
}

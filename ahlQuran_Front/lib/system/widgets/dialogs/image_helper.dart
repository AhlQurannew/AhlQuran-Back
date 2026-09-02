import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';

class ImageHelper {
  static const int maxImageSizeBytes = 5 * 1024 * 1024;

  static Future<String?> uploadImage(File image, String endpoint) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'https://example.com/uploaded_image.jpg';
  }

  static Future<File?> pickImage(
      BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile == null) return null;

      File file = File(pickedFile.path);
      file = await _cropImage(file);
      file = await _compressImage(file);

      if (file.lengthSync() > maxImageSizeBytes) {
        Get.snackbar('Error', 'Image size exceeds 5MB limit');
        return null;
      }

      return file;
    } catch (e, stackTrace) {
      dev.log('Error picking image', error: e, stackTrace: stackTrace);
      Get.snackbar('Error', 'Failed to pick image');
      return null;
    }
  }

  static Future<File> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      '${file.path}_compressed.jpg',
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );
    return result != null ? File(result.path) : file;
  }

  static Future<File> _cropImage(File file) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Get.theme.primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : file;
  }

  static Future<String?> uploadImageFile(File image) async {
    try {
      return await uploadImage(image, ApiEndpoints.uploadImage);
    } catch (e, stackTrace) {
      dev.log('Upload failed', error: e, stackTrace: stackTrace);
      Get.snackbar('Upload Failed', 'Could not upload the image');
      return null;
    }
  }
}

import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File?) onImagePicked;
  final String? initialImageUrl;

  const ImagePickerWidget({
    super.key,
    required this.onImagePicked,
    this.initialImageUrl,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
        widget.onImagePicked(_pickedImage);
      }
    } catch (e) {
      dev.log('Error picking image: $e');
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _pickedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _pickedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : widget.initialImageUrl != null &&
                      widget.initialImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.initialImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.error)),
                      ),
                    )
                  : Center(
                      child: Text(
                        'لم يتم رفع أي ملف',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose file'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF2A9D8F), // Teal color from screenshot
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'قم بسحب وإسقاط ملف هنا للتحميل',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

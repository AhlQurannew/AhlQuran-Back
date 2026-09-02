import 'dart:developer' as log;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
//import 'package:permission_handler/permission_handler.dart';

//Android specific
/* class HandlePermission {
 Future<bool> requestPermission() async {
    try {
//when you await a Future, it unwraps the Future and deaives you the actual value
      PermissionStatus status = await Permission.photos.request();
      //repeated if else => use switch
      switch (status) {
        case PermissionStatus.granted:
          log.log('Permission granted');
          return true;
        case PermissionStatus.denied:
          log.log('Permission denied');
          return false;
        case PermissionStatus.permanentlyDenied:
          //The user has explicitly denied the permission and selected "Don't ask again"
          log.log('Permission permanently denied');
          //open settings to allow the user to change the permission
          openAppSettings(); //silently does nothing (no error, but no effect).
          return false;
        case PermissionStatus.restricted:
          // The user can't grant this permission even if they want to.
          log.log('Permission restricted');
          return false;
        //isLimited cannot be used for Android—it is iOS-only
        default:
          log.log('Permission not determined');
          return false;
      }
      //isLimited cannot be used for Android—it is iOS-only
    } catch (e) {
      log.log(e.toString());
      return false;
    }
  }
}*/

class Picker extends StatefulWidget {
  const Picker({super.key});

  @override
  State<Picker> createState() => _PickerState();
}

/*
Yes — a variable declared inside a try block is scoped to that block, meaning you can't access it outside unless you declare it before the try.
*/
//_image local variables should not be private
//Private (_) in Dart is library-scoped, not class-scoped or function-scoped.
//local var do not need extra encapsulation
/*
      When Should You Use _ (Private)?
      Only for class fields or top-level variables
      what is top level var?
      a top-level variable is a variable declared outside of any class, function, or method—
      */
class _PickerState extends State<Picker> {
  XFile? imageFile;
  // HandlePermission handlePermission = HandlePermission();

  Future<void> imageselector() async {
    try {
      //permission
      imageFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      setState(() {});
    } catch (e) {
      log.log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildImage(imageFile);
  }
}

/*
//mobile only 
    Image.file(
      File(image.path),
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );

}*/
Widget buildImage(XFile? imageFile) {
  if (imageFile != null) {
    return FutureBuilder(
      future: imageFile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Image.memory(
            //multiplatform
            snapshot.data as Uint8List,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          );
        } else if (snapshot.hasError) {
          return const Text('Error loading image');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  } else {
    return const Text('No image selected.');
  }
}

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class Generate extends GetxController {
  String generateUsername(
      TextEditingController lastName, TextEditingController firstName) {
    if (firstName.text.isNotEmpty && lastName.text.isNotEmpty) {
      Random random = Random();
      String ln = lastName.text.trim();
      String fn = firstName.text.trim();
      String lnPart = ln.length >= 3 ? ln.substring(0, 3) : ln;
      String fnPart = fn.length >= 3 ? fn.substring(0, 3) : fn;
      String username = lnPart + fnPart + random.nextInt(10).toString();
      return username;
    }
    return "please enter your name";
  }

  String generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#%&*';
    const length = 10;
    final Random random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}

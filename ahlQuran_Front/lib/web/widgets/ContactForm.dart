import 'package:flutter/material.dart';

class ContactForm extends StatefulWidget {
  @override
  _ContactFormState createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isHuman = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 5000, // Ajuste la largeur du formulaire
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Fond blanc
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              spreadRadius: 2,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "تفضّل بطرح سؤالك",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField("الاسم الكامل")),
                      SizedBox(width: 15),
                      Expanded(child: _buildTextField("البريد الإلكتروني")),
                    ],
                  ),
                  SizedBox(height: 15),
                  _buildTextField("الموضوع"),
                  SizedBox(height: 16),
                  _buildTextField("الرسالة", maxLines: 4),
                  SizedBox(height: 20),
                  _buildRecaptcha(),
                  SizedBox(height: 20),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1}) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? "هذا الحقل مطلوب" : null,
    );
  }

  Widget _buildRecaptcha() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _isHuman,
          onChanged: (value) {
            setState(() {
              _isHuman = value!;
            });
          },
        ),
        Text("أنا لست برنامج روبوت"),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate() && _isHuman) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تم الإرسال بنجاح")),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text("إرسال الآن", style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}

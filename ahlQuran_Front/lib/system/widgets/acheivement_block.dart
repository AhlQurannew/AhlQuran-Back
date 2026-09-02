import 'package:flutter/material.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/achivement_unit/surah_ayah.dart';
import './input_field.dart';
import './drop_down.dart';
import '/system/utils/const/acheivement.dart';

class AcheivementBlock extends StatefulWidget {
  final SurahAyah surahAyah;
  final Function()? onDelete;
  final Function()? onSave;
  const AcheivementBlock(
      {super.key,
      required this.surahAyah,
      required this.onDelete,
      required this.onSave});

  @override
  State<AcheivementBlock> createState() => _AcheivementBlockState();
}

class _AcheivementBlockState extends State<AcheivementBlock> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: InputField(
              inputTitle: "from surah",
              child: DropDownWidget(
                items: surah,
                initialValue: null,
                onSaved: (p0) => widget.surahAyah.fromSurahName = p0,
                validator: (p0) {
                  if (p0 == null) {
                    return "required";
                  }
                  return null;
                },
              )),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
              inputTitle: "from ayah",
              child: DropDownWidget(
                items: ayahNumbers,
                initialValue: null,
                onSaved: (p0) => widget.surahAyah.fromAyahNumber = p0,
                validator: (p0) {
                  if (p0 == null) {
                    return "required";
                  }
                  return null;
                },
              )),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
              inputTitle: "to surah",
              child: DropDownWidget(
                items: surah,
                initialValue: null,
                onSaved: (p0) => widget.surahAyah.toSurahName = p0,
                validator: (p0) {
                  if (p0 == null) {
                    return "required";
                  }
                  return null;
                },
              )),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
              inputTitle: "to surah",
              child: DropDownWidget(
                items: ayahNumbers,
                initialValue: null,
                onSaved: (p0) => widget.surahAyah.toAyahNumber = p0,
                validator: (p0) {
                  if (p0 == null) {
                    return "required";
                  }
                  return null;
                },
              )),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
              inputTitle: "observation",
              child: DropDownWidget(
                items: observations,
                initialValue: null,
                onSaved: (p0) => widget.surahAyah.observation = p0,
              )),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: () {
            widget.onDelete!();
          },
        ),
      ],
    );
  }
}

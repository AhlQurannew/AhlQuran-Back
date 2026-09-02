import 'surah_ayah.dart';

class SurahAyahList {
  List<SurahAyah> surahAyahList = [];

  SurahAyahList();

  void addSurahAyah() {
    surahAyahList.add(SurahAyah());
  }

  void removeSurahAyah(int index) {
    surahAyahList.removeAt(index);
  }

  Map<String, dynamic> toJson() => {
        'surahAyahList': surahAyahList.map((item) => item.toJson()).toList(),
      };
}

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class Setting {

  static const String appName = 'Wouri TV';
  static const String appName_web = 'Wouri TV, Le Carrefour des cinémas d\'Afrique.';
  static const String currenversion = '4.2.1';
  static const String plateforme = '5';
  static const String plateforme_web = '8';
  static const String plateforme_pc = '7';
  static const String plateforme_tv = '6';

  static const mobileWidth = 600;
  static const desktopWidth = 1400;
  static const int paiement = 1; //1 desactive les paiements, 0 laisser les paiements
  
  static const version_name_short = '4.2.1';
  static const version_name = 'Version 4.2.1 - © 2024 Wouri TV';

  static String getDate(String jour) {
    List<String> dat1 = jour.split(" ");
    List<String> dat2 = dat1[0].split("-");
    return "${dat2[2]}/${dat2[1]}/${dat2[0]}";
  }

  static String getDate2(String jour) {
    List<String> dat2 = jour.split("-");
    return "${dat2[2]}/${dat2[1]}/${dat2[0]}";
  }

  static String generateRandomString(int len) {
    var r = Random();
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
  }

  static const int cacheTimeout = 15 * 60 * 1000; // 15 minutes
  static const int cacheTimeout2 = 1 * 60 * 60 * 1000; // 1 hour
  static const int cacheTimeout3 = 2 * 60 * 1000; // 1 hour

  static const bgColor = Color(0xFF000000);
  static const primaryColor = Color(0xFFcd005f);  
  static const white = Color(0xFFFFFFFF);
  static const bottomNavBarbg = Color(0xFF191919);
  static const gris = Color(0xFFF4F4F4);
  static const secondColor = Color(0xFFe48cc4);
  static const tailleRequest = 30;
  static const encryptKey = "WELCOMEONWOURITV";
  static const ivKey = "fedcba9876543210";

  static String ArrayToString(List<String> list) {
    String retour = "";
    for(int i = 0; i < list.length; i++) {
      if(i != list.length - 1) retour+= "${list[i].trim()}, ";
      else retour+= list[i].trim();
    }
    return retour;
  }


 static String formatedTime(int timeInSecond) {
    int sec = timeInSecond % 60;
    int min = (timeInSecond / 60).floor();
    String minute = min.toString().length <= 1 ? "0$min" : "$min";
    String second = sec.toString().length <= 1 ? "0$sec" : "$sec";
    return "$minute : $second";
}



}
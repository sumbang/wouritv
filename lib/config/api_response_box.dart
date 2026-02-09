import 'package:hive/hive.dart';

part 'api_response_box.g.dart';  //here my file name is api_response_box.dart

@HiveType(typeId: 0) //declare unique for every class
class ApiResponseBox extends HiveObject {
  @HiveField(0) //unique index of the field
  late String url;

  @HiveField(1)
  late String response;

  @HiveField(2)
  late int timestamp;
}
import 'package:hive/hive.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'user_model.g.dart';

@HiveType(typeId: HiveTypeIds.user)
class UserOffline extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String avatar;

  UserOffline({required this.name, required this.avatar});
}

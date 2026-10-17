import 'Genericclass.dart';

class People extends Genericclass<Object> {
  People({
    required int id,
    required String name,
    required String description,
  }) : super(id: id, name: name, description: description);
}

import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsService {
  Future<bool> requestPermission() async {
    return FlutterContacts.requestPermission();
  }

  Future<List<Contact>> fetchContacts() async {
    final allowed = await requestPermission();
    if (!allowed) {
      return [];
    }
    return FlutterContacts.getContacts(withProperties: true);
  }
}

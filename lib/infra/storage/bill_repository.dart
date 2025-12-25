import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/bill.dart';

class BillRepository {
  static const _boxName = 'bills';

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }

  Future<void> saveBill(Bill bill) async {
    final box = await Hive.openBox(_boxName);
    await box.put(bill.id, bill.toJson());
  }

  Future<List<Bill>> fetchBills() async {
    final box = await Hive.openBox(_boxName);
    return box.values
        .map((value) => Bill.fromJson(Map<String, dynamic>.from(value)))
        .toList();
  }

  Future<Bill?> fetchBill(String id) async {
    final box = await Hive.openBox(_boxName);
    final value = box.get(id);
    if (value == null) {
      return null;
    }
    return Bill.fromJson(Map<String, dynamic>.from(value));
  }
}

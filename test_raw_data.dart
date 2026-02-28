import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final client = SupabaseClient(dotenv.env['SUPABASE_URL']!, dotenv.env['SUPABASE_ANON_KEY']!);
  final data = await client.from('items').select('id, tipo, raw_data').limit(5);
  for (var item in data) {
    print("Item: \${item['id']} Type: \${item['tipo']}");
    print("Raw Data type: \${item['raw_data'].runtimeType}");
    print("Raw Data: \${item['raw_data']}");
  }
}

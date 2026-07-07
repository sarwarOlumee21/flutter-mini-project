import 'web_data_store_stub.dart'
    if (dart.library.html) 'web_data_store_web.dart';

class WebDataStore {
  static String? read() => readWebData();

  static void write(String value) => writeWebData(value);
}

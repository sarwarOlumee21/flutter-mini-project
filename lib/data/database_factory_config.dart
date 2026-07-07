import 'database_factory_config_stub.dart'
    if (dart.library.html) 'database_factory_config_web.dart';

void configureDatabaseFactory() {
  configureDatabaseFactoryForPlatform();
}

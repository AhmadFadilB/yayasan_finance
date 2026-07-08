export 'excel_saver_stub.dart'
    if (dart.library.html) 'excel_saver_web.dart'
    if (dart.library.io) 'excel_saver_mobile.dart';

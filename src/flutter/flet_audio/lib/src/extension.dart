import 'package:flet/flet.dart';

import 'audio.dart';

class Extension extends FletExtension {
  @override
  FletService? createService(Control control, FletBackend backend) {
    switch (control.type) {
      case "Audio":
        return AudioService(control: control, backend: backend);
      default:
        return null;
    }
  }
}

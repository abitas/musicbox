import 'dart:io';
import 'dart:async';

final SystemInfo systemInfo = SystemInfo();

class SystemInfo {
  late Future<SystemInfo> systemInfoFuture;
  //late String documentsfolderPath;
  //late String abbadofolderPath;
  String platform= Platform.operatingSystem; // Possible values include: "android" "fuchsia" "ios" "linux" "macos" "windows"
  bool runningApple= (Platform.isIOS) | (Platform.isMacOS);
  
  SystemInfo() {
    systemInfoFuture = loadSystemInfo();
  }

  Future<SystemInfo> loadSystemInfo() async {
    //documentsfolderPath=await getdefaultDirectory();
    //abbadofolderPath= '$documentsfolderPath/abbado/';
    return this;
  }
}

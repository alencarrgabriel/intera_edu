import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/server_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carrega URL custom de servidor antes da UI subir — assim ApiClient já tem
  // o host correto quando faz a primeira chamada.
  await ServerConfig.instance.init();
  runApp(const InteraEduApp());
}

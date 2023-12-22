import 'package:translator/translator.dart';

GoogleTranslator translator = GoogleTranslator();
String translate_text = "";

Future<String> translated(String text) async {
  final Translation translation =
      await translator.translate(text, from: 'en', to: 'vi');
  final String out = translation.toString();
  print('Out ${out}');
  return out;
}

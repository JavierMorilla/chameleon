import 'word_bank_es.dart';
import 'words_en.dart';
import 'words_de.dart';

export 'word_bank_es.dart' show GameWord;

const Map<String, List<GameWord>> kWordBank = kWordBankEs;

Map<String, List<GameWord>> getWordBank(String lang) {
  switch (lang) {
    case 'en':
      return kWordBankEn;
    case 'de':
      return kWordBankDe;
    case 'es':
    default:
      return kWordBankEs;
  }
}

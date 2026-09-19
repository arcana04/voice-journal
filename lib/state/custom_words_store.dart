import 'package:flutter/foundation.dart';

import '../models/custom_word.dart';
import '../services/custom_words_service.dart';

enum AddCustomWordResult {
  success,
  empty,
  duplicate,
  limitReached,
  wordTooLong,
}

class CustomWordsStore extends ChangeNotifier {
  final CustomWordsService _service = CustomWordsService();

  // functions/src/index.tsのnormalizeCustomWordsが課す上限(100件・単語40文字・
  // 説明80文字)と揃える。以前はここでは無制限に追加でき、上限超過分はサーバー側で
  // 無言で切り捨てられていた(ユーザーは自分の登録が実際には使われていないことに
  // 気づけなかった)ため、ここで先に同じ上限を課してその場でフィードバックする。
  static const maxWords = 100;
  static const maxWordLength = 40;
  static const maxDescriptionLength = 80;

  List<CustomWord> words = [];
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    words = await _service.getWords();
    _loaded = true;
    notifyListeners();
  }

  /// プロンプトの区切り・見出しと誤認されるのを防ぐため、改行・制御文字は
  /// 保存前に空白へ潰す（用語集はAIへの分類プロンプトへそのまま埋め込まれるため、
  /// 改行を含む単語がプロンプト構造に紛れ込む余地を無くす）。
  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[\r\n\t\x00-\x1F\x7F]+'), ' ').trim();
  }

  Future<AddCustomWordResult> addWord(String word, {String? description}) async {
    final trimmed = _sanitize(word);
    if (trimmed.isEmpty) return AddCustomWordResult.empty;
    if (trimmed.length > maxWordLength) return AddCustomWordResult.wordTooLong;
    // 大文字小文字だけが違う重複("Alice"/"alice")も同一語として弾く——
    // 区別すると両方がWhisperのプロンプトヒント・AIの用語集コンテキストへ
    // 重複して送られ、無駄なノイズになっていた
    // （[[project_voicejournal_knowledge_base_chat]]参照）。
    if (words.any((w) => w.word.toLowerCase() == trimmed.toLowerCase())) {
      return AddCustomWordResult.duplicate;
    }
    if (words.length >= maxWords) return AddCustomWordResult.limitReached;

    final trimmedDescription = description == null ? '' : _sanitize(description);
    final sanitizedDescription = trimmedDescription.isEmpty
        ? null
        : trimmedDescription.substring(
            0,
            trimmedDescription.length.clamp(0, maxDescriptionLength),
          );
    words = [
      ...words,
      CustomWord(word: trimmed, description: sanitizedDescription),
    ];
    await _service.setWords(words);
    notifyListeners();
    return AddCustomWordResult.success;
  }

  Future<void> removeWord(CustomWord word) async {
    words = words.where((w) => w.word != word.word).toList();
    await _service.setWords(words);
    notifyListeners();
  }

  /// アカウント切り替え/アカウント削除時、前の持ち主の登録語をメモリ上からも
  /// 消す（[CustomWordsService.clear]は永続化層だけなので、これを呼ばないと
  /// 画面上には次の再起動までwordsが残ったまま表示されてしまう）。
  Future<void> clear() async {
    words = [];
    await _service.clear();
    notifyListeners();
  }
}

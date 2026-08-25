import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/custom_words_store.dart';

/// 友達の名前・専門用語などを登録しておくと、録音時にWhisperへヒントとして
/// 渡され、音声認識の誤変換を減らせる。
class CustomDictionaryScreen extends StatefulWidget {
  const CustomDictionaryScreen({super.key});

  @override
  State<CustomDictionaryScreen> createState() => _CustomDictionaryScreenState();
}

class _CustomDictionaryScreenState extends State<CustomDictionaryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addWord() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<CustomWordsStore>().addWord(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final words = context.watch<CustomWordsStore>().words;

    return Scaffold(
      appBar: AppBar(title: const Text('カスタム辞書')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '友達の名前、ゼミ名、専門用語などを登録しておくと、録音時の音声認識で優先的に候補に使われます。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '例: 山田太郎、量子力学ゼミ',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addWord(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addWord,
                  child: const Text('追加'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: words.isEmpty
                ? Center(
                    child: Text(
                      '登録された単語はまだありません',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: words.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final word = words[index];
                      return ListTile(
                        title: Text(word),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: '削除',
                          onPressed: () =>
                              context.read<CustomWordsStore>().removeWord(word),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

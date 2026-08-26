import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/custom_words_store.dart';

/// 友達の名前・専門用語などを登録しておくと、録音時にWhisperへヒントとして
/// 渡され、音声認識の誤変換を減らせる。説明を添えるとAIによる表記の後修正にも使われる。
class CustomDictionaryScreen extends StatefulWidget {
  const CustomDictionaryScreen({super.key});

  @override
  State<CustomDictionaryScreen> createState() => _CustomDictionaryScreenState();
}

class _CustomDictionaryScreenState extends State<CustomDictionaryScreen> {
  final _wordController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _wordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addWord() {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;
    context.read<CustomWordsStore>().addWord(
          word,
          description: _descriptionController.text.trim(),
        );
    _wordController.clear();
    _descriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final words = context.watch<CustomWordsStore>().words;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customDictionaryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              l10n.customDictionaryDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              children: [
                TextField(
                  controller: _wordController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.wordLabel,
                    hintText: l10n.wordHint,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descriptionController,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: l10n.descriptionLabelOptional,
                          hintText: l10n.descriptionHint,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addWord(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addWord,
                      child: Text(l10n.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          Expanded(
            child: words.isEmpty
                ? Center(
                    child: Text(
                      l10n.customDictionaryEmpty,
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
                        title: Text(word.word),
                        subtitle: word.description != null ? Text(word.description!) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: l10n.delete,
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

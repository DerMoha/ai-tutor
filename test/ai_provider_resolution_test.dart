import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_tutor/ai_tutor/data/database/ai_tutor_database.dart';
import 'package:ai_tutor/ai_tutor/data/repositories/ai_repository.dart';
import 'package:ai_tutor/ai_tutor/models/conversation.dart';
import 'package:ai_tutor/ai_tutor/models/enums.dart';
import 'package:ai_tutor/ai_tutor/services/ai/ai_provider.dart';
import 'package:ai_tutor/ai_tutor/services/ai/api_key_store.dart';
import 'package:ai_tutor/ai_tutor/services/ai/provider_registry.dart';
import 'package:ai_tutor/ai_tutor/state/ai_chat_state.dart';
import 'package:ai_tutor/ai_tutor/state/provider_config_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI provider resolution', () {
    test('shared registry includes MiniMax provider and template', () {
      expect(AiProviderRegistry.providerFor('minimax'), isNotNull);

      final minimaxTemplate = AiProviderRegistry.templates.where(
        (template) => template.id == 'minimax',
      );

      expect(minimaxTemplate, hasLength(1));
      expect(
        ProviderConfigState.providerTemplates,
        AiProviderRegistry.templates,
      );
    });

    test(
      'chat reloads provider config and resolves MiniMax saved after startup',
      () async {
        final originalProvider = AiProviderRegistry.providers['minimax'];
        final fakeProvider = _FakeAiProvider();
        AiProviderRegistry.providers['minimax'] = fakeProvider;

        final db = AiTutorDatabase.forTesting(NativeDatabase.memory());
        final repo = AiRepository(db);
        final keyStore = _MemoryApiKeyStore();
        final chatState = AiChatState(
          aiRepository: repo,
          apiKeyStore: keyStore,
        );
        final providerState = ProviderConfigState(apiKeyStore: keyStore);

        addTearDown(() async {
          if (originalProvider == null) {
            AiProviderRegistry.providers.remove('minimax');
          } else {
            AiProviderRegistry.providers['minimax'] = originalProvider;
          }
          chatState.dispose();
          await db.close();
        });

        await providerState.saveProvider(
          providerId: 'minimax',
          label: 'MiniMax',
          model: 'MiniMax-M2.5',
          apiKey: 'test-key',
          baseUrl: 'https://api.minimax.io/v1',
        );

        await chatState.openConversation(
          targetType: ConversationTargetType.document,
          targetId: 'doc-1',
        );

        await chatState.sendMessage('Explain derivatives simply.');
        await Future<void>.delayed(Duration.zero);

        expect(chatState.error, isNull);
        expect(fakeProvider.sendChatCallCount, 1);
        expect(fakeProvider.lastConfig?.model, 'MiniMax-M2.5');
        expect(fakeProvider.lastConfig?.baseUrl, 'https://api.minimax.io/v1');
        expect(chatState.messages, hasLength(2));
        expect(chatState.messages.first.role, MessageRole.user);
        expect(chatState.messages.first.content, 'Explain derivatives simply.');
        expect(chatState.messages.last.role, MessageRole.assistant);
        expect(chatState.messages.last.content, 'MiniMax is available.');
      },
    );
  });
}

class _MemoryApiKeyStore extends ApiKeyStore {
  final Map<String, String> _keys = {};
  final List<ProviderConfig> _configs = [];
  String? _activeProviderId;

  @override
  Future<List<ProviderConfig>> getConfigs() async =>
      List.unmodifiable(_configs);

  @override
  Future<void> saveConfig(ProviderConfig config) async {
    final index = _configs.indexWhere((c) => c.providerId == config.providerId);
    if (index >= 0) {
      _configs[index] = config;
    } else {
      _configs.add(config);
    }
  }

  @override
  Future<void> deleteConfig(String providerId) async {
    _configs.removeWhere((config) => config.providerId == providerId);
    _keys.remove(providerId);
  }

  @override
  Future<void> saveApiKey(String providerId, String apiKey) async {
    _keys[providerId] = apiKey;
  }

  @override
  Future<String?> getApiKey(String providerId) async => _keys[providerId];

  @override
  Future<void> deleteApiKey(String providerId) async {
    _keys.remove(providerId);
  }

  @override
  Future<String?> getActiveProviderId() async => _activeProviderId;

  @override
  Future<void> setActiveProviderId(String providerId) async {
    _activeProviderId = providerId;
  }
}

class _FakeAiProvider implements AiProvider {
  ProviderRuntimeConfig? lastConfig;
  AiChatRequest? lastRequest;
  int sendChatCallCount = 0;

  @override
  String get id => 'minimax';

  @override
  Future<void> testConnection(ProviderRuntimeConfig config) async {}

  @override
  Stream<AiStreamChunk> sendChat(
    ProviderRuntimeConfig config,
    AiChatRequest request,
  ) async* {
    sendChatCallCount += 1;
    lastConfig = config;
    lastRequest = request;
    yield const AiStreamChunk(content: 'MiniMax is available.');
    yield const AiStreamChunk(content: '', isDone: true);
  }

  @override
  Future<String> generateQuiz(
    ProviderRuntimeConfig config,
    QuizGenerationRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<String> summarize(ProviderRuntimeConfig config, String content) async {
    throw UnimplementedError();
  }

  @override
  Future<String> complete(
    ProviderRuntimeConfig config,
    AiChatRequest request,
  ) async {
    throw UnimplementedError();
  }
}

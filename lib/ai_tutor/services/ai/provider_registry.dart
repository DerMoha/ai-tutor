import '../../models/conversation.dart';
import 'ai_provider.dart';
import 'openai_provider.dart';

class AiProviderTemplate {
  const AiProviderTemplate({
    required this.id,
    required this.label,
    required this.defaultModel,
    required this.baseUrl,
    required this.models,
  });

  final String id;
  final String label;
  final String defaultModel;
  final String? baseUrl;
  final List<String> models;
}

class AiProviderRegistry {
  static final Map<String, AiProvider> providers = {
    'openai': OpenAiProvider(),
    'openrouter': OpenAiProvider(providerId: 'openrouter'),
    'minimax': OpenAiProvider(providerId: 'minimax'),
  };

  static const List<AiProviderTemplate> templates = [
    AiProviderTemplate(
      id: 'openai',
      label: 'OpenAI',
      defaultModel: 'gpt-4o',
      baseUrl: null,
      models: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'o3-mini'],
    ),
    AiProviderTemplate(
      id: 'openrouter',
      label: 'OpenRouter',
      defaultModel: 'anthropic/claude-sonnet-4',
      baseUrl: 'https://openrouter.ai/api/v1',
      models: [
        'openrouter/free',
        'anthropic/claude-sonnet-4',
        'anthropic/claude-haiku-4',
        'google/gemini-2.5-flash',
        'openai/gpt-4o',
      ],
    ),
    AiProviderTemplate(
      id: 'minimax',
      label: 'MiniMax',
      defaultModel: 'MiniMax-M2.5',
      baseUrl: 'https://api.minimax.io/v1',
      models: [
        'MiniMax-M2.7',
        'MiniMax-M2.7-highspeed',
        'MiniMax-M2.5',
        'MiniMax-M2.5-highspeed',
        'MiniMax-M2.1',
        'MiniMax-M2.1-highspeed',
        'MiniMax-M2',
      ],
    ),
  ];

  static AiProvider? providerFor(String providerId) => providers[providerId];

  static ProviderConfig? activeConfig(
    List<ProviderConfig> configs,
    String? activeProviderId,
  ) {
    if (activeProviderId == null) return null;
    try {
      return configs.firstWhere(
        (config) => config.providerId == activeProviderId,
      );
    } catch (_) {
      return null;
    }
  }
}

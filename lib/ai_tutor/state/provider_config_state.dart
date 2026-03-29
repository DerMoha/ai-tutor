import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../services/ai/api_key_store.dart';
import '../services/ai/ai_provider.dart';
import '../services/ai/provider_registry.dart';

/// Manages AI provider configuration and API keys.
class ProviderConfigState extends ChangeNotifier {
  ProviderConfigState({required ApiKeyStore apiKeyStore})
    : _keyStore = apiKeyStore {
    _load();
  }

  final ApiKeyStore _keyStore;

  final Map<String, AiProvider> _providers = AiProviderRegistry.providers;

  List<ProviderConfig> _configs = [];
  String? _activeProviderId;
  bool _isLoading = true;
  bool _isTesting = false;
  String? _testResult;

  List<ProviderConfig> get configs => _configs;
  String? get activeProviderId => _activeProviderId;
  bool get isLoading => _isLoading;
  bool get isTesting => _isTesting;
  String? get testResult => _testResult;

  /// Available provider templates for the setup screen.
  static const providerTemplates = AiProviderRegistry.templates;

  Future<void> _load() async {
    _configs = await _keyStore.getConfigs();
    _activeProviderId = await _keyStore.getActiveProviderId();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveProvider({
    required String providerId,
    required String label,
    required String model,
    required String apiKey,
    String? baseUrl,
  }) async {
    final config = ProviderConfig(
      providerId: providerId,
      label: label,
      model: model,
      baseUrl: baseUrl,
    );
    await _keyStore.saveConfig(config);
    await _keyStore.saveApiKey(providerId, apiKey);

    _activeProviderId ??= providerId;
    await _keyStore.setActiveProviderId(_activeProviderId!);

    await _load();
  }

  Future<void> deleteProvider(String providerId) async {
    await _keyStore.deleteConfig(providerId);
    if (_activeProviderId == providerId) {
      final remaining = await _keyStore.getConfigs();
      _activeProviderId = remaining.isNotEmpty
          ? remaining.first.providerId
          : null;
      if (_activeProviderId != null) {
        await _keyStore.setActiveProviderId(_activeProviderId!);
      }
    }
    await _load();
  }

  Future<void> setActiveProvider(String providerId) async {
    _activeProviderId = providerId;
    await _keyStore.setActiveProviderId(providerId);
    notifyListeners();
  }

  Future<void> testConnection({
    required String providerId,
    required String apiKey,
    required String model,
    String? baseUrl,
  }) async {
    _isTesting = true;
    _testResult = null;
    notifyListeners();

    try {
      final provider = _providers[providerId];
      if (provider == null) throw Exception('Unknown provider: $providerId');

      await provider.testConnection(
        ProviderRuntimeConfig(apiKey: apiKey, model: model, baseUrl: baseUrl),
      );
      _testResult = 'Connection successful!';
    } catch (e) {
      _testResult = 'Failed: $e';
    } finally {
      _isTesting = false;
      notifyListeners();
    }
  }

  void clearTestResult() {
    _testResult = null;
    notifyListeners();
  }
}

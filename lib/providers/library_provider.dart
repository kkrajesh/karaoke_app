import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vox_player_core/vox_player_core.dart';
import '../services/youtube_service.dart';
import '../services/smule_service.dart';
import 'app_state_provider.dart';
import 'vox_search_providers.dart';

final voxSearchProvidersProvider = Provider<List<VoxSearchProvider>>((ref) {
  final ytService = ref.watch(youtubeServiceProvider);
  final smuleService = ref.watch(smuleServiceProvider);
  final hostIp = ref.watch(clientHostIpProvider);

  String? hostUrl;
  if (hostIp != null) {
    hostUrl = 'http://$hostIp:5000';
  }

  return [
    YoutubeVoxSearchProvider(ytService),
    MediaMonkeySearchProvider(hostUrl: hostUrl, prioritizeLocal: false),
    SmuleVoxSearchProvider(smuleService),
  ];
});

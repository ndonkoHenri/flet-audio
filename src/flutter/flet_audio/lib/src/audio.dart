import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:flet/flet.dart';
import 'package:flutter/foundation.dart';

class AudioService extends FletService {
  AudioService({required super.control, required super.backend});

  AudioPlayer player = AudioPlayer();
  Duration? _duration;
  int _position = -1;
  StreamSubscription? _onDurationChangedSubscription;
  StreamSubscription? _onStateChangedSubscription;
  StreamSubscription? _onPositionChangedSubscription;
  StreamSubscription? _onSeekCompleteSubscription;

  String? _src;
  String? _srcBase64;
  ReleaseMode? _releaseMode;
  double? _volume;
  double? _balance;
  double? _playbackRate;

  @override
  void init() {
    super.init();
    debugPrint("Audio(${control.id}).init: ${control.properties}");
    control.addInvokeMethodListener(_invokeMethod);

    _onDurationChangedSubscription =
        player.onDurationChanged.listen((duration) {
      backend.triggerControlEvent(
          control, "duration_changed", {"duration": duration.inMilliseconds});
      _duration = duration;
    });

    _onStateChangedSubscription = player.onPlayerStateChanged.listen((state) {
      debugPrint("Audio($hashCode) - state_changed: ${state.name}");
      backend
          .triggerControlEvent(control, "state_changed", {"state": state.name});
    });

    _onPositionChangedSubscription =
        player.onPositionChanged.listen((position) {
      int posMs = (position.inMilliseconds / 1000).round() * 1000;
      if (posMs != _position) {
        _position = posMs;
      } else if (position.inMilliseconds == _duration?.inMilliseconds) {
        _position = _duration!.inMilliseconds;
      } else {
        return;
      }
      backend.triggerControlEvent(
          control, "position_changed", {"position": posMs});
    });

    _onSeekCompleteSubscription = player.onSeekComplete.listen((event) {
      backend.triggerControlEvent(control, "seek_complete");
    });

    update();
  }

  @override
  void update() {
    debugPrint("Audio(${control.id}).update: ${control.properties}");

    var src = control.getString("src", "")!;
    var srcBase64 = control.getString("src_base64", "")!;
    if (src == "" && srcBase64 == "") {
      throw Exception(
          "Audio must have either \"src\" or \"src_base64\" specified.");
    }
    bool autoplay = control.getBool("autoplay", false)!;
    double? volume = control.getDouble("volume", null);
    double? balance = control.getDouble("balance", null);
    double? playbackRate = control.getDouble("playback_rate", null);
    var releaseMode = ReleaseMode.values.firstWhereOrNull((e) =>
        e.name.toLowerCase() ==
        control.getString("release_mode", "")!.toLowerCase());

    () async {
      bool srcChanged = false;
      if (src != "" && src != _src) {
        _src = src;
        srcChanged = true;

        // URL or file?
        var assetSrc = backend.getAssetSource(src);
        if (assetSrc.isFile) {
          await player.setSourceDeviceFile(assetSrc.path);
        } else {
          await player.setSourceUrl(assetSrc.path);
        }
      } else if (srcBase64 != "" && srcBase64 != _srcBase64) {
        _srcBase64 = srcBase64;
        srcChanged = true;
        await player.setSourceBytes(base64Decode(srcBase64));
      }

      if (srcChanged) {
        debugPrint("Audio.srcChanged");
        backend.triggerControlEvent(control, "loaded");
      }

      if (releaseMode != null && releaseMode != _releaseMode) {
        debugPrint("Audio.setReleaseMode($releaseMode)");
        _releaseMode = releaseMode;
        await player.setReleaseMode(releaseMode);
      }

      if (volume != _volume && volume != null && volume >= 0 && volume <= 1) {
        _volume = volume;
        debugPrint("Audio.setVolume($volume)");
        await player.setVolume(volume);
      }

      if (playbackRate != _playbackRate &&
          playbackRate != null &&
          playbackRate >= 0 &&
          playbackRate <= 2) {
        _playbackRate = playbackRate;
        debugPrint("Audio.setPlaybackRate($playbackRate)");
        await player.setPlaybackRate(playbackRate);
      }

      if (!kIsWeb &&
          balance != _balance &&
          balance != null &&
          balance >= -1 &&
          balance <= 1) {
        _balance = balance;
        debugPrint("Audio.setBalance($balance)");
        await player.setBalance(balance);
      }

      if (srcChanged && autoplay) {
        debugPrint("Audio.resume($srcChanged, $autoplay)");
        await player.resume();
      }
    }();
  }

  Future<dynamic> _invokeMethod(String name, dynamic args) async {
    debugPrint("Audio.$name($args)");
    switch (name) {
      case "play":
        await player.seek(const Duration(milliseconds: 0));
        await player.resume();
        break;
      case "resume":
        await player.resume();
        break;
      case "pause":
        await player.pause();
        break;
      case "release":
        await player.release();
        break;
      case "seek":
        await player.seek(Duration(milliseconds: args["position"] ?? 0));
        break;
      case "get_duration":
        return (await player.getDuration())?.inMilliseconds;
      case "get_current_position":
        return (await player.getCurrentPosition())?.inMilliseconds;
      default:
        throw Exception("Unknown Audio method: $name");
    }
  }

  @override
  void dispose() {
    debugPrint("Audio(${control.id}).dispose()");
    control.removeInvokeMethodListener(_invokeMethod);
    _onDurationChangedSubscription?.cancel();
    _onStateChangedSubscription?.cancel();
    _onPositionChangedSubscription?.cancel();
    _onSeekCompleteSubscription?.cancel();
    super.dispose();
  }
}

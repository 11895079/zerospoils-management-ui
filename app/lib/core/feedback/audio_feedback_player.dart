library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

abstract class AudioFeedbackPlayer {
  Future<void> playBeep({required double volume});
}

/// Plays a short generated sine beep via an in-memory WAV payload so volume
/// can be controlled directly from app settings.
class DefaultAudioFeedbackPlayer implements AudioFeedbackPlayer {
  DefaultAudioFeedbackPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  Uint8List? _cachedTone;

  @override
  Future<void> playBeep({required double volume}) async {
    final safeVolume = volume.clamp(0.0, 1.0);
    if (safeVolume <= 0) {
      return;
    }

    await _configureForScannerBeep();

    _cachedTone ??= _generateWavTone(
      frequencyHz: 1380,
      durationMs: 85,
      sampleRate: 22050,
      amplitude: 0.55,
    );

    await _player.setVolume(safeVolume);
    await _player.play(BytesSource(_cachedTone!));
  }

  Future<void> _configureForScannerBeep() async {
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (_) {}

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}

    try {
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
    } catch (_) {}
  }

  Uint8List _generateWavTone({
    required int frequencyHz,
    required int durationMs,
    required int sampleRate,
    required double amplitude,
  }) {
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final dataSize = sampleCount * 2;
    final totalSize = 44 + dataSize;
    final bytes = ByteData(totalSize);

    void writeString(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    bytes.setUint32(4, totalSize - 8, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);

    final maxAmp = (32767 * amplitude).round();
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final envelope = math.min(1.0, i / (sampleRate * 0.006));
      final sample =
          (math.sin(2 * math.pi * frequencyHz * t) * maxAmp * envelope)
              .round()
              .clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, sample, Endian.little);
    }

    return bytes.buffer.asUint8List();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngoma/core/formatting/duration_format.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class MessagingLocalInput {
  const MessagingLocalInput({
    required this.sourceUri,
    required this.type,
    required this.label,
    this.mimeType,
    this.sizeBytes,
    this.durationMs,
    this.waveform = const [],
  });

  final String sourceUri;
  final String type;
  final String label;
  final String? mimeType;
  final int? sizeBytes;
  final int? durationMs;
  final List<double> waveform;
}

abstract class MessagingInputService {
  Stream<double> get voiceAmplitude;

  Future<List<MessagingLocalInput>> capturePhoto();
  Future<List<MessagingLocalInput>> pickMedia();
  Future<List<MessagingLocalInput>> pickDocuments();
  Future<List<MessagingLocalInput>> pickCurrentLocation();
  Future<bool> startVoiceRecording();
  Future<MessagingLocalInput?> stopVoiceRecording();
  Future<void> cancelVoiceRecording();
  Future<void> playVoicePreview(String sourceUri);
  Future<void> stopVoicePreview();
  Future<void> dispose();
}

final messagingInputServiceProvider =
    Provider.autoDispose<MessagingInputService>((ref) {
      final service = PluginMessagingInputService();
      ref.onDispose(service.dispose);
      return service;
    });

class PluginMessagingInputService implements MessagingInputService {
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final StreamController<double> _amplitude =
      StreamController<double>.broadcast();

  StreamSubscription<Amplitude>? _amplitudeSubscription;
  DateTime? _voiceStartedAt;
  String? _voicePath;
  final List<double> _waveform = [];
  int _waveformCursor = 0;

  @override
  Stream<double> get voiceAmplitude => _amplitude.stream;

  @override
  Future<List<MessagingLocalInput>> capturePhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );
    if (file == null) return const [];
    return [await _fromXFile(file, type: 'image')];
  }

  @override
  Future<List<MessagingLocalInput>> pickMedia() async {
    final files = await _imagePicker.pickMultipleMedia(imageQuality: 88);
    return Future.wait(files.map(_fromMediaFile));
  }

  Future<MessagingLocalInput> _fromMediaFile(XFile file) async {
    final mimeType = file.mimeType ?? _mimeTypeFor(file.name);
    final isVideo = mimeType?.startsWith('video/') ?? false;
    return _fromXFile(file, type: isVideo ? 'video' : 'image');
  }

  Future<MessagingLocalInput> _fromXFile(
    XFile file, {
    required String type,
  }) async => MessagingLocalInput(
    sourceUri: file.path,
    type: type,
    label: file.name,
    mimeType: file.mimeType ?? _mimeTypeFor(file.name),
    sizeBytes: await file.length(),
  );

  @override
  Future<List<MessagingLocalInput>> pickDocuments() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result == null) return const [];
    return result.files
        .where((file) => file.path != null)
        .map(
          (file) => MessagingLocalInput(
            sourceUri: file.path!,
            type: 'document',
            label: file.name,
            mimeType: _mimeTypeFor(file.name),
            sizeBytes: file.size,
          ),
        )
        .toList();
  }

  @override
  Future<List<MessagingLocalInput>> pickCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const MessagingInputException('LOCATION_SERVICE_DISABLED');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const MessagingInputException('LOCATION_PERMISSION_DENIED');
    }
    final position = await Geolocator.getCurrentPosition();
    return [
      MessagingLocalInput(
        sourceUri: 'geo:${position.latitude},${position.longitude}',
        type: 'location',
        label: 'Position actuelle',
        mimeType: 'application/geo+json',
      ),
    ];
  }

  @override
  Future<bool> startVoiceRecording() async {
    await stopVoicePreview();
    if (!await _recorder.hasPermission()) return false;
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}${Platform.pathSeparator}wouanda-voice-${DateTime.now().microsecondsSinceEpoch}.m4a';
    _waveform.clear();
    _waveformCursor = 0;
    _voicePath = path;
    _voiceStartedAt = DateTime.now();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((sample) {
          final normalized = ((sample.current + 60) / 60).clamp(0.0, 1.0);
          if (_waveform.length < 64) {
            _waveform.add(normalized);
          } else {
            _waveform[_waveformCursor % 64] = normalized;
            _waveformCursor++;
          }
          _amplitude.add(normalized);
        });
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: path,
    );
    return true;
  }

  @override
  Future<MessagingLocalInput?> stopVoiceRecording() async {
    final startedAt = _voiceStartedAt;
    final path = await _recorder.stop();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _voiceStartedAt = null;
    if (path == null || startedAt == null) return null;
    final duration = DateTime.now().difference(startedAt);
    final file = File(path);
    return MessagingLocalInput(
      sourceUri: path,
      type: 'voice',
      label: 'Vocal ${_formatDuration(duration)}',
      mimeType: 'audio/mp4',
      sizeBytes: await file.length(),
      durationMs: duration.inMilliseconds,
      waveform: List.unmodifiable(_waveform),
    );
  }

  @override
  Future<void> cancelVoiceRecording() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    if (await _recorder.isRecording()) await _recorder.cancel();
    final path = _voicePath;
    _voicePath = null;
    _voiceStartedAt = null;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<void> playVoicePreview(String sourceUri) =>
      _player.play(DeviceFileSource(sourceUri, mimeType: 'audio/mp4'));

  @override
  Future<void> stopVoicePreview() => _player.stop();

  @override
  Future<void> dispose() async {
    await _amplitudeSubscription?.cancel();
    await _recorder.dispose();
    await _player.dispose();
    await _amplitude.close();
  }
}

class MessagingInputException implements Exception {
  const MessagingInputException(this.code);
  final String code;
}

String _formatDuration(Duration value) => formatClock(value);

String? _mimeTypeFor(String name) {
  final extension = name.split('.').last.toLowerCase();
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'm4a' => 'audio/mp4',
    'mp3' => 'audio/mpeg',
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt' => 'text/plain',
    _ => null,
  };
}

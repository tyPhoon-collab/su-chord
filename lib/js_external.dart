@JS()
library audio_input;

import 'dart:html';

import 'package:js/js.dart';

@JS('startRec')
external void startRec(int bufferSize, [int sampleRate]);

@JS('stopRec')
external void stopRec();

@JS('getAudioBuffer')
external Blob getAudioBuffer();

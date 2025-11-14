/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:chatview/src/utils/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

import '../../chatview.dart';
import '../utils/debounce.dart';
import '../utils/package_strings.dart';

class ChatUITextField extends StatefulWidget {
  const ChatUITextField(
      {super.key,
      this.sendMessageConfig,
      required this.focusNode,
      required this.textEditingController,
      required this.onPressed,
      required this.onRecordingComplete,
      required this.onImageSelected,
      required this.onLocationSelected});

  /// Provides configuration of default text field in chat.
  final SendMessageConfiguration? sendMessageConfig;

  /// Provides focusNode for focusing text field.
  final FocusNode focusNode;

  /// Provides functions which handles text field.
  final TextEditingController textEditingController;

  /// Provides callback when user tap on text field.
  final VoidCallBack onPressed;

  /// Provides callback once voice is recorded.
  final Function(String?) onRecordingComplete;

  /// Provides callback when user select images from camera/gallery.
  final StringsCallBack onImageSelected;

  /// Provides callback when user selects a location.
  final LocationCallBack onLocationSelected;

  @override
  State<ChatUITextField> createState() => _ChatUITextFieldState();
}

class _ChatUITextFieldState extends State<ChatUITextField> {
  final ValueNotifier<String> _inputText = ValueNotifier('');
  final ValueNotifier<bool> _isFocused = ValueNotifier(false);

  final ImagePicker _imagePicker = ImagePicker();

  RecorderController? controller;

  ValueNotifier<bool> isRecording = ValueNotifier(false);

  SendMessageConfiguration? get sendMessageConfig => widget.sendMessageConfig;

  VoiceRecordingConfiguration? get voiceRecordingConfig =>
      widget.sendMessageConfig?.voiceRecordingConfiguration;

  ImagePickerIconsConfiguration? get imagePickerIconsConfig =>
      sendMessageConfig?.imagePickerIconsConfig;

  LocationPickerIconsConfiguration? get locationPickerIconsConfig =>
      sendMessageConfig?.locationPickerIconsConfig;

  TextFieldConfiguration? get textFieldConfig =>
      sendMessageConfig?.textFieldConfig;

  CancelRecordConfiguration? get cancelRecordConfiguration =>
      sendMessageConfig?.cancelRecordConfiguration;

  OutlineInputBorder get _outLineBorder => OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: widget.sendMessageConfig?.textFieldConfig?.borderRadius ??
            BorderRadius.circular(textFieldBorderRadius),
      );

  ValueNotifier<TypeWriterStatus> composingStatus =
      ValueNotifier(TypeWriterStatus.typed);

  late Debouncer debouncer;

  @override
  void initState() {
    attachListeners();
    debouncer = Debouncer(
        sendMessageConfig?.textFieldConfig?.compositionThresholdTime ??
            const Duration(seconds: 1));
    super.initState();

    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      controller = RecorderController();
    }
  }

  @override
  void dispose() {
    debouncer.dispose();
    composingStatus.dispose();
    isRecording.dispose();
    _inputText.dispose();
    super.dispose();
  }

  void attachListeners() {
    composingStatus.addListener(() {
      widget.sendMessageConfig?.textFieldConfig?.onMessageTyping
          ?.call(composingStatus.value);
    });

    widget.focusNode.addListener(() {
      _isFocused.value = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final outlineBorder = _outLineBorder;
    return Container(
      padding:
          textFieldConfig?.padding ?? const EdgeInsets.symmetric(horizontal: 6),
      margin: textFieldConfig?.margin,
      decoration: BoxDecoration(
        borderRadius: textFieldConfig?.borderRadius ??
            BorderRadius.circular(textFieldBorderRadius),
        color: sendMessageConfig?.textFieldBackgroundColor ?? Colors.white,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: isRecording,
        builder: (_, isRecordingValue, child) {
          return Row(
            children: [
              // Camera and Gallery buttons OUTSIDE the input field
              if (!isRecordingValue) ...[
                if (sendMessageConfig?.enableCameraImagePicker ?? true)
                  IconButton(
                    constraints: const BoxConstraints(),
                    onPressed: (textFieldConfig?.enabled ?? true)
                        ? () => _onIconPressed(
                              ImageSource.camera,
                              config: sendMessageConfig?.imagePickerConfiguration,
                            )
                        : null,
                    icon: imagePickerIconsConfig?.cameraImagePickerIcon ??
                        Icon(
                          Icons.camera_alt_outlined,
                          color: imagePickerIconsConfig?.cameraIconColor,
                        ),
                  ),
                if (sendMessageConfig?.enableGalleryImagePicker ?? true)
                  IconButton(
                    constraints: const BoxConstraints(),
                    onPressed: (textFieldConfig?.enabled ?? true)
                        ? () => _onIconPressed(
                              ImageSource.gallery,
                              config: sendMessageConfig?.imagePickerConfiguration,
                            )
                        : null,
                    icon: imagePickerIconsConfig?.galleryImagePickerIcon ??
                        Icon(
                          Icons.image,
                          color: imagePickerIconsConfig?.galleryIconColor,
                        ),
                  ),
              ],
              if (isRecordingValue && controller != null && !kIsWeb)
                Expanded(
                  child: AudioWaveforms(
                    size: const Size(double.maxFinite, 50),
                    recorderController: controller!,
                    margin: voiceRecordingConfig?.margin,
                    padding: voiceRecordingConfig?.padding ??
                        EdgeInsets.symmetric(
                          horizontal: cancelRecordConfiguration == null ? 8 : 5,
                        ),
                    decoration: voiceRecordingConfig?.decoration ??
                        BoxDecoration(
                          color: voiceRecordingConfig?.backgroundColor,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                    waveStyle: voiceRecordingConfig?.waveStyle ??
                        WaveStyle(
                          extendWaveform: true,
                          showMiddleLine: false,
                          waveColor:
                              voiceRecordingConfig?.waveStyle?.waveColor ??
                                  Colors.black,
                        ),
                  ),
                )
              else
                Expanded(
                  child: TextField(
                    focusNode: widget.focusNode,
                    controller: widget.textEditingController,
                    style: textFieldConfig?.textStyle ??
                        const TextStyle(color: Colors.white),
                    maxLines: textFieldConfig?.maxLines ?? 5,
                    minLines: textFieldConfig?.minLines ?? 1,
                    keyboardType: textFieldConfig?.textInputType,
                    inputFormatters: textFieldConfig?.inputFormatters,
                    onChanged: _onChanged,
                    enabled: textFieldConfig?.enabled,
                    textCapitalization: textFieldConfig?.textCapitalization ??
                        TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          textFieldConfig?.hintText ?? PackageStrings.message,
                      fillColor: sendMessageConfig?.textFieldBackgroundColor ??
                          Colors.white,
                      filled: true,
                      hintStyle: textFieldConfig?.hintStyle ??
                          TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.25,
                          ),
                      contentPadding: textFieldConfig?.contentPadding ??
                          const EdgeInsets.symmetric(horizontal: 6),
                      border: outlineBorder,
                      focusedBorder: outlineBorder,
                      enabledBorder: outlineBorder,
                      disabledBorder: outlineBorder,
                    ),
                  ),
                ),
              // Send button and location picker - show based on focus/text
              ValueListenableBuilder<String>(
                valueListenable: _inputText,
                builder: (_, inputTextValue, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isFocused,
                    builder: (_, isFocused, child) {
                      final hasText = inputTextValue.isNotEmpty;
                      final showSendButton = hasText || isFocused;

                      return Row(
                        children: [
                          // Location picker - show when not recording, no text, and not focused
                          if (!isRecordingValue &&
                              !hasText &&
                              !isFocused &&
                              (sendMessageConfig?.enableLocationPicker ?? false) &&
                              sendMessageConfig?.locationPickerCallback != null)
                            IconButton(
                              constraints: const BoxConstraints(),
                              onPressed: (textFieldConfig?.enabled ?? true)
                                  ? () async {
                                      LatLng? location =
                                          await sendMessageConfig
                                              ?.locationPickerCallback!
                                              .call();
                                      widget.onLocationSelected(location);
                                    }
                                  : null,
                              icon: locationPickerIconsConfig
                                      ?.locationPickerIcon ??
                                  Icon(
                                    Icons.near_me,
                                    color: locationPickerIconsConfig
                                        ?.locationPickerIconColor,
                                  ),
                            ),
                          // Voice recording buttons
                          if (!isRecordingValue &&
                              (sendMessageConfig?.allowRecordingVoice ?? false) &&
                              !kIsWeb &&
                              (Platform.isIOS || Platform.isAndroid) &&
                              !hasText)
                            IconButton(
                              onPressed: (textFieldConfig?.enabled ?? true)
                                  ? _recordOrStop
                                  : null,
                              icon: voiceRecordingConfig?.micIcon ??
                                  Icon(
                                    Icons.mic,
                                    color: voiceRecordingConfig?.recorderIconColor,
                                  ),
                            ),
                          if (isRecordingValue)
                            IconButton(
                              onPressed: (textFieldConfig?.enabled ?? true)
                                  ? _recordOrStop
                                  : null,
                              icon: voiceRecordingConfig?.stopIcon ??
                                  Icon(
                                    Icons.stop,
                                    color: voiceRecordingConfig?.recorderIconColor,
                                  ),
                            ),
                          if (isRecordingValue &&
                              cancelRecordConfiguration != null)
                            IconButton(
                              onPressed: () {
                                cancelRecordConfiguration?.onCancel?.call();
                                _cancelRecording();
                              },
                              icon: cancelRecordConfiguration?.icon ??
                                  const Icon(Icons.cancel_outlined),
                              color: cancelRecordConfiguration?.iconColor ??
                                  voiceRecordingConfig?.recorderIconColor,
                            ),
                          // Send button - only show when focused or has text
                          if (showSendButton && !isRecordingValue)
                            IconButton(
                              color: sendMessageConfig?.defaultSendButtonColor ??
                                  Colors.green,
                              onPressed: hasText && (textFieldConfig?.enabled ?? true)
                                  ? () {
                                      widget.onPressed();
                                      _inputText.value = '';
                                    }
                                  : null,
                              icon: sendMessageConfig?.sendButtonIcon ??
                                  const Icon(Icons.send),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  FutureOr<void> _cancelRecording() async {
    assert(
      defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android,
      "Voice messages are only supported with android and ios platform",
    );
    if (!isRecording.value) return;
    final path = await controller?.stop();
    if (path == null) {
      isRecording.value = false;
      return;
    }
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }

    isRecording.value = false;
  }

  Future<void> _recordOrStop() async {
    assert(
      defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android,
      "Voice messages are only supported with android and ios platform",
    );
    if (!isRecording.value) {
      await controller?.record(
        sampleRate: voiceRecordingConfig?.sampleRate,
        bitRate: voiceRecordingConfig?.bitRate,
        androidEncoder: voiceRecordingConfig?.androidEncoder,
        iosEncoder: voiceRecordingConfig?.iosEncoder,
        androidOutputFormat: voiceRecordingConfig?.androidOutputFormat,
      );
      isRecording.value = true;
    } else {
      final path = await controller?.stop();
      isRecording.value = false;
      widget.onRecordingComplete(path);
    }
  }

  void _onIconPressed(
    ImageSource imageSource, {
    ImagePickerConfiguration? config,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: imageSource,
        maxHeight: config?.maxHeight,
        maxWidth: config?.maxWidth,
        imageQuality: config?.imageQuality,
        preferredCameraDevice:
            config?.preferredCameraDevice ?? CameraDevice.rear,
      );
      String? imagePath = image?.path;
      if (config?.onImagePicked != null) {
        String? updatedImagePath = await config?.onImagePicked!(imagePath);
        if (updatedImagePath != null) imagePath = updatedImagePath;
      }
      widget.onImageSelected(imagePath ?? '', '');
    } catch (e) {
      widget.onImageSelected('', e.toString());
    }
  }

  void _onChanged(String inputText) {
    debouncer.run(() {
      composingStatus.value = TypeWriterStatus.typed;
    }, () {
      composingStatus.value = TypeWriterStatus.typing;
    });
    _inputText.value = inputText;
  }
}

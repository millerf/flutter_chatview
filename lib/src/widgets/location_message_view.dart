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
import 'package:chatview/chatview.dart';
import 'package:chatview/src/widgets/receipt_widget.dart';
import 'package:flutter/material.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

import '../utils/constants/constants.dart';
import 'reaction_widget.dart';

class LocationMessageView extends StatelessWidget {
  const LocationMessageView(
      {super.key,
      required this.isMessageByCurrentUser,
      required this.message,
      this.chatBubbleMaxWidth,
      this.inComingChatBubbleConfig,
      this.outgoingChatBubbleConfig,
      this.receiptWidgetConfig,
      this.messageReactionConfig,
      this.highlightMessage = false,
      this.highlightColor,
      this.onLocationClick});

  /// Represents current message is sent by current user.
  final bool isMessageByCurrentUser;

  /// Provides message instance of chat.
  final Message message;

  /// Allow users to give max width of chat bubble.
  final double? chatBubbleMaxWidth;

  /// Provides configuration of chat bubble appearance from other user of chat.
  final ChatBubble? inComingChatBubbleConfig;

  /// Provides configuration of chat bubble appearance from current user of chat.
  final ChatBubble? outgoingChatBubbleConfig;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents message should highlight.
  final bool highlightMessage;

  /// Allow user to set color of highlighted message.
  final Color? highlightColor;

  /// Receipt config
  final ReceiptsWidgetConfig? receiptWidgetConfig;

  /// Allow to do something on location click
  final LocationCallBack? onLocationClick;

  @override
  Widget build(BuildContext context) {
    final LatLng? position = getLocationFromMessage(message);
    if (position == null) {
      return SizedBox();
    }
    return Container(
      margin: _margin ??
          EdgeInsets.fromLTRB(
              5, 0, 6, message.reaction.reactions.isNotEmpty ? 15 : 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
                decoration: BoxDecoration(
                  color: highlightMessage ? highlightColor : _color,
                  borderRadius: _borderRadius(''),
                ),
                padding: _padding ??
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                child: SizedBox(
                  width: chatBubbleMaxWidth ??
                      MediaQuery.of(context).size.width * 0.5,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: _borderRadius(''),
                    ),
                    child: PlatformMap(
                      compassEnabled: false,
                      zoomControlsEnabled: false,
                      rotateGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      markers: {
                        Marker(
                          markerId: MarkerId(message.id.toString()),
                          position: position,
                          onTap: () {
                            if (onLocationClick != null) {
                              onLocationClick!(position);
                            }
                          },
                        )
                      },
                      initialCameraPosition:
                          CameraPosition(target: position, zoom: 10),
                    ),
                  ),
                )),
            if (message.reaction.reactions.isNotEmpty)
              ReactionWidget(
                key: key,
                isMessageByCurrentUser: isMessageByCurrentUser,
                reaction: message.reaction,
                messageReactionConfig: messageReactionConfig,
              ),
          ],
        ),
        ReceiptWidget(
            message: message,
            receiptWidgetConfig: receiptWidgetConfig,
            isMessageByCurrentUser: isMessageByCurrentUser),
      ]),
    );
  }

  EdgeInsetsGeometry? get _padding => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.padding
      : inComingChatBubbleConfig?.padding;

  EdgeInsetsGeometry? get _margin => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.margin
      : inComingChatBubbleConfig?.margin;

  BorderRadiusGeometry _borderRadius(String message) => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.borderRadius ??
          (message.length < 37
              ? BorderRadius.circular(replyBorderRadius1)
              : BorderRadius.circular(replyBorderRadius2))
      : inComingChatBubbleConfig?.borderRadius ??
          (message.length < 29
              ? BorderRadius.circular(replyBorderRadius1)
              : BorderRadius.circular(replyBorderRadius2));

  Color get _color => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.color ?? Colors.purple
      : inComingChatBubbleConfig?.color ?? Colors.grey.shade500;
}

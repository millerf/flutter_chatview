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
import 'package:chatview/src/extensions/extensions.dart';
import 'package:chatview/src/widgets/receipt_widget.dart';
import 'package:flutter/material.dart';

import 'chat_bubble_tail_painter.dart';
import 'link_preview.dart';
import 'reaction_widget.dart';

/// Enum to represent the position of a message within a grouped sequence
enum MessageGroupPosition {
  /// Single message (not part of a group)
  single,
  /// First message in a group
  first,
  /// Middle message in a group
  middle,
  /// Last message in a group
  last,
}

class TextMessageView extends StatelessWidget {
  const TextMessageView({
    super.key,
    required this.isMessageByCurrentUser,
    required this.message,
    this.chatBubbleMaxWidth,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.receiptWidgetConfig,
    this.messageReactionConfig,
    this.highlightMessage = false,
    this.highlightColor,
    this.previousMessage,
    this.nextMessage,
  });

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

  final ReceiptsWidgetConfig? receiptWidgetConfig;

  /// Previous message for grouping context
  final Message? previousMessage;

  /// Next message for grouping context
  final Message? nextMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textMessage = message.message;
    return Container(
      margin: _getAdjustedMargin(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Bubble tail - disabled for now as it renders incorrectly
              // if (_shouldShowTail())
              //   Positioned(
              //     bottom: 0,
              //     left: isMessageByCurrentUser ? null : 0,
              //     right: isMessageByCurrentUser ? 0 : null,
              //     child: CustomPaint(
              //       size: const Size(8, 8),
              //       painter: ChatBubbleTailPainter(
              //         color: highlightMessage
              //             ? (highlightColor ?? _color)
              //             : _color,
              //         isIncoming: !isMessageByCurrentUser,
              //       ),
              //     ),
              //   ),
              Container(
                  decoration: BoxDecoration(
                    color: highlightMessage ? highlightColor : _color,
                    borderRadius: _borderRadius(textMessage),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: _padding ??
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                  child: Container(
                    constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width * 0.3,
                        maxWidth: chatBubbleMaxWidth ??
                            MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textMessage.isUrl
                            ? LinkPreview(
                                linkPreviewConfig: _linkPreviewConfig,
                                url: textMessage,
                              )
                            : Text(
                                textMessage,
                                style: _textStyle ??
                                    textTheme.bodyMedium!.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                              ),
                      ],
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
          // Only show receipts for single messages or last message in a group
          if (_shouldShowReceipts())
            ReceiptWidget(
                message: message,
                receiptWidgetConfig: receiptWidgetConfig,
                isMessageByCurrentUser: isMessageByCurrentUser),
        ],
      ),
    );
  }

  /// Determines if receipts (timestamp and status) should be shown
  /// Only show for single messages or the last message in a group
  bool _shouldShowReceipts() {
    final position = _getMessageGroupPosition();
    return position == MessageGroupPosition.single ||
        position == MessageGroupPosition.last;
  }

  /// Determines if bubble tail should be shown
  /// Only show for single messages or the last message in a group
  bool _shouldShowTail() {
    final position = _getMessageGroupPosition();
    return position == MessageGroupPosition.single ||
        position == MessageGroupPosition.last;
  }

  /// Gets adjusted margin based on message grouping position
  EdgeInsetsGeometry _getAdjustedMargin() {
    final position = _getMessageGroupPosition();
    final baseMargin = _margin ??
        EdgeInsets.fromLTRB(5, 0, 6, message.reaction.reactions.isNotEmpty ? 15 : 2);

    // Reduce vertical spacing for grouped messages (except last one which needs space for receipts)
    if (position == MessageGroupPosition.first || position == MessageGroupPosition.middle) {
      return EdgeInsets.fromLTRB(
        baseMargin.horizontal / 2,
        0,
        baseMargin.horizontal / 2,
        0, // No spacing between grouped messages (WhatsApp-style)
      );
    }

    return baseMargin;
  }

  EdgeInsetsGeometry? get _padding => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.padding
      : inComingChatBubbleConfig?.padding;

  EdgeInsetsGeometry? get _margin => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.margin
      : inComingChatBubbleConfig?.margin;

  LinkPreviewConfiguration? get _linkPreviewConfig => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.linkPreviewConfig
      : inComingChatBubbleConfig?.linkPreviewConfig;

  TextStyle? get _textStyle => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.textStyle
      : inComingChatBubbleConfig?.textStyle;

  BorderRadiusGeometry _borderRadius(String messageText) {
    // If custom borderRadius is provided, use it
    final customBorderRadius = isMessageByCurrentUser
        ? outgoingChatBubbleConfig?.borderRadius
        : inComingChatBubbleConfig?.borderRadius;

    if (customBorderRadius != null) {
      return customBorderRadius;
    }

    // Determine message grouping position
    final position = _getMessageGroupPosition();

    // Base and tight radius values
    const double baseRadius = 12.0;
    const double tightRadius = 4.0;

    // Apply WhatsApp-style border radius based on position and direction
    return _getGroupedBorderRadius(position, baseRadius, tightRadius);
  }

  /// Determines the position of this message within a grouped sequence
  MessageGroupPosition _getMessageGroupPosition() {
    // Don't group with previous if THIS message is a reply (needs to show reply context)
    final bool groupWithPrevious =
        message.replyMessage == null && _shouldGroupWith(previousMessage);

    // Don't group with next if NEXT message is a reply (it needs to show its reply context)
    final bool groupWithNext =
        (nextMessage?.replyMessage == null) && _shouldGroupWith(nextMessage);

    if (!groupWithPrevious && !groupWithNext) {
      return MessageGroupPosition.single;
    } else if (groupWithPrevious && groupWithNext) {
      return MessageGroupPosition.middle;
    } else if (!groupWithPrevious && groupWithNext) {
      return MessageGroupPosition.first;
    } else {
      return MessageGroupPosition.last;
    }
  }

  /// Checks if this message should be grouped with another message
  bool _shouldGroupWith(Message? other) {
    if (other == null) return false;

    // Must be from the same sender
    if (message.sentBy != other.sentBy) return false;

    // Must be within 1 minute of each other
    final timeDiff = message.createdAt.difference(other.createdAt).abs();
    return timeDiff <= const Duration(minutes: 1);
  }

  /// Returns the appropriate BorderRadius based on message position and direction
  BorderRadius _getGroupedBorderRadius(
    MessageGroupPosition position,
    double baseRadius,
    double tightRadius,
  ) {
    switch (position) {
      case MessageGroupPosition.single:
        // All corners fully rounded
        return BorderRadius.circular(baseRadius);

      case MessageGroupPosition.first:
        // Top corners fully rounded, bottom corner tight on sender's side
        if (isMessageByCurrentUser) {
          return BorderRadius.only(
            topLeft: Radius.circular(baseRadius),
            topRight: Radius.circular(baseRadius),
            bottomLeft: Radius.circular(baseRadius),
            bottomRight: Radius.circular(tightRadius),
          );
        } else {
          return BorderRadius.only(
            topLeft: Radius.circular(baseRadius),
            topRight: Radius.circular(baseRadius),
            bottomLeft: Radius.circular(tightRadius),
            bottomRight: Radius.circular(baseRadius),
          );
        }

      case MessageGroupPosition.middle:
        // Top and bottom corners tight on sender's side
        if (isMessageByCurrentUser) {
          return BorderRadius.only(
            topLeft: Radius.circular(baseRadius),
            topRight: Radius.circular(tightRadius),
            bottomLeft: Radius.circular(baseRadius),
            bottomRight: Radius.circular(tightRadius),
          );
        } else {
          return BorderRadius.only(
            topLeft: Radius.circular(tightRadius),
            topRight: Radius.circular(baseRadius),
            bottomLeft: Radius.circular(tightRadius),
            bottomRight: Radius.circular(baseRadius),
          );
        }

      case MessageGroupPosition.last:
        // Bottom corners fully rounded, top corner tight on sender's side
        if (isMessageByCurrentUser) {
          return BorderRadius.only(
            topLeft: Radius.circular(baseRadius),
            topRight: Radius.circular(tightRadius),
            bottomLeft: Radius.circular(baseRadius),
            bottomRight: Radius.circular(baseRadius),
          );
        } else {
          return BorderRadius.only(
            topLeft: Radius.circular(tightRadius),
            topRight: Radius.circular(baseRadius),
            bottomLeft: Radius.circular(baseRadius),
            bottomRight: Radius.circular(baseRadius),
          );
        }
    }
  }

  Color get _color => isMessageByCurrentUser
      ? outgoingChatBubbleConfig?.color ?? Colors.purple
      : inComingChatBubbleConfig?.color ?? Colors.grey.shade500;
}

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
import 'dart:convert';
import 'dart:io';

import 'package:chatview/src/extensions/extensions.dart';
import 'package:chatview/src/models/models.dart';
import 'package:flutter/material.dart';

import 'reaction_widget.dart';
import 'receipt_widget.dart';
import 'share_icon.dart';

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

class ImageMessageView extends StatelessWidget {
  const ImageMessageView({
    super.key,
    required this.message,
    required this.isMessageByCurrentUser,
    this.imageMessageConfig,
    this.messageReactionConfig,
    this.highlightImage = false,
    this.highlightScale = 1.2,
    this.receiptWidgetConfig,
    this.previousMessage,
    this.nextMessage,
  });

  /// Provides message instance of chat.
  final Message message;

  /// Represents current message is sent by current user.
  final bool isMessageByCurrentUser;

  /// Provides configuration for image message appearance.
  final ImageMessageConfiguration? imageMessageConfig;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents flag of highlighting image when user taps on replied image.
  final bool highlightImage;

  /// Provides scale of highlighted image when user taps on replied image.
  final double highlightScale;

  /// Receipt widget configuration for time/status display
  final ReceiptsWidgetConfig? receiptWidgetConfig;

  /// Previous message for grouping context
  final Message? previousMessage;

  /// Next message for grouping context
  final Message? nextMessage;

  String get imageUrl => message.message;

  Widget get iconButton => ShareIcon(
        shareIconConfig: imageMessageConfig?.shareIconConfig,
        imageUrl: imageUrl,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: _getAdjustedMargin(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isMessageByCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (isMessageByCurrentUser &&
                  !(imageMessageConfig?.hideShareIcon ?? false))
                iconButton,
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => imageMessageConfig?.onTap != null
                        ? imageMessageConfig?.onTap!(message)
                        : null,
                    child: Transform.scale(
                      scale: highlightImage ? highlightScale : 1.0,
                      alignment: isMessageByCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: imageMessageConfig?.padding ?? EdgeInsets.zero,
                        margin: EdgeInsets.only(
                          top: 6,
                          right: isMessageByCurrentUser ? 6 : 0,
                          left: isMessageByCurrentUser ? 0 : 6,
                          bottom: message.reaction.reactions.isNotEmpty ? 15 : 0,
                        ),
                        height: imageMessageConfig?.height ?? 200,
                        width: imageMessageConfig?.width ?? 150,
                        child: ClipRRect(
                          borderRadius: _borderRadius(),
                          child: (() {
                            if (imageUrl.isUrl) {
                              return Image.network(
                                imageUrl,
                                fit: BoxFit.fitHeight,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress
                                                  .expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              );
                            } else if (imageUrl.fromMemory) {
                              return Image.memory(
                                base64Decode(imageUrl
                                    .substring(imageUrl.indexOf('base64') + 7)),
                                fit: BoxFit.fill,
                              );
                            } else {
                              return Image.file(
                                File(imageUrl),
                                fit: BoxFit.fill,
                              );
                            }
                          }()),
                        ),
                      ),
                    ),
                  ),
                  if (message.reaction.reactions.isNotEmpty)
                    ReactionWidget(
                      isMessageByCurrentUser: isMessageByCurrentUser,
                      reaction: message.reaction,
                      messageReactionConfig: messageReactionConfig,
                    ),
                ],
              ),
              if (!isMessageByCurrentUser &&
                  !(imageMessageConfig?.hideShareIcon ?? false))
                iconButton,
            ],
          ),
          // Only show receipts for single messages or last message in a group
          if (_shouldShowReceipts())
            ReceiptWidget(
              message: message,
              receiptWidgetConfig: receiptWidgetConfig,
              isMessageByCurrentUser: isMessageByCurrentUser,
            ),
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

  /// Gets adjusted margin based on message grouping position
  EdgeInsetsGeometry _getAdjustedMargin() {
    final position = _getMessageGroupPosition();

    // Reduce vertical spacing for grouped messages
    if (position == MessageGroupPosition.first ||
        position == MessageGroupPosition.middle) {
      return EdgeInsets.fromLTRB(
        12, // Left margin
        0, // No top margin
        12, // Right margin
        0, // No bottom margin for grouped messages
      );
    }

    // Last message or single message - normal spacing
    return EdgeInsets.fromLTRB(
      12,
      0,
      12,
      message.reaction.reactions.isNotEmpty ? 15 : 2,
    );
  }

  BorderRadiusGeometry _borderRadius() {
    // If custom borderRadius is provided, use it
    if (imageMessageConfig?.borderRadius != null) {
      return imageMessageConfig!.borderRadius!;
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
    // Don't group with previous if THIS message is a reply
    final bool groupWithPrevious =
        message.replyMessage == null && _shouldGroupWith(previousMessage);

    // Don't group with next if NEXT message is a reply
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
}

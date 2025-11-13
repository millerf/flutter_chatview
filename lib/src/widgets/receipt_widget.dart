import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptWidget extends StatelessWidget {
  final Message message;
  final bool isMessageByCurrentUser;
  final ReceiptsWidgetConfig? receiptWidgetConfig;

  const ReceiptWidget({
    super.key,
    required this.message,
    required this.receiptWidgetConfig,
    required this.isMessageByCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt.toLocal();
    final timeFormat = receiptWidgetConfig?.timeFormat ?? DateFormat('hh:mm a');

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeFormat.format(time),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isMessageByCurrentUser
                  ? (receiptWidgetConfig?.receiptColorCurrentUser ??
                      Colors.black)
                  : (receiptWidgetConfig?.receiptColor ?? Colors.grey)),
        ),
        if (isMessageByCurrentUser) SizedBox(width: 5),
        if (isMessageByCurrentUser)
          ValueListenableBuilder(
            valueListenable: message.statusNotifier,
            builder: (context, MessageStatus value, child) {
              switch (value) {
                case MessageStatus.undelivered:
                  // Make failed message tappable for retry
                  return InkWell(
                    onTap: receiptWidgetConfig?.onRetry != null
                        ? () => receiptWidgetConfig!.onRetry!(message)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  );
                case MessageStatus.read:
                  return Icon(Icons.done_all, color: Colors.blue, size: 16);
                case MessageStatus.delivered:
                  return Icon(Icons.done_all, color: Colors.grey, size: 16);
                case MessageStatus.pending:
                  return SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  );
              }
            },
          ),
      ],
    );
  }
}

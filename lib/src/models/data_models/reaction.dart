import 'package:chatview/chatview.dart';

class Reaction {
  Reaction({
    required this.reactions,
    required this.reactedUserIds,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    final reactionsList = json['reactions'] is List<dynamic>
        ? json['reactions'] as List<dynamic>
        : <dynamic>[];

    final reactions = <String>[
      for (var i = 0; i < reactionsList.length; i++)
        if (reactionsList[i]?.toString().isNotEmpty ?? false)
          reactionsList[i]!.toString()
    ];

    final reactedUserIdList = json['reactedUserIds'] is List<dynamic>
        ? json['reactedUserIds'] as List<dynamic>
        : <dynamic>[];

    final reactedUserIds = <int>[
      for (var i = 0; i < reactedUserIdList.length; i++)
        if (reactedUserIdList[i]!=userEmptyId)
          reactedUserIdList[i]
    ];

    return Reaction(
      reactions: reactions,
      reactedUserIds: reactedUserIds,
    );
  }

  /// Provides list of reaction in single message.
  final List<String> reactions;

  /// Provides list of user who reacted on message.
  final List<int> reactedUserIds;

  Map<String, dynamic> toJson() => {
        'reactions': reactions,
        'reactedUserIds': reactedUserIds,
      };

  Reaction copyWith({
    List<String>? reactions,
    List<int>? reactedUserIds,
  }) {
    return Reaction(
      reactions: reactions ?? this.reactions,
      reactedUserIds: reactedUserIds ?? this.reactedUserIds,
    );
  }
}

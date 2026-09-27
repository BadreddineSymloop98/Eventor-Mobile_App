import 'package:flutter/widgets.dart';

import '../../messaging/models/chat_person.dart';
import '../../messaging/models/conversation.dart';
import '../atoms/app_avatar.dart';

/// The avatar for a conversation row (14) or a chat header (15) — which of
/// [AppAvatar]'s several faces to show depends on the thread's [kind], not
/// only on who [other] is.
class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    required this.kind,
    required this.other,
    required this.size,
    super.key,
  });

  final ConversationKind kind;

  /// The other side of a one-to-one thread. Unused for [ConversationKind.support]
  /// and [ConversationKind.dispute], which always show their own face.
  final ChatPerson? other;
  final AppAvatarSize size;

  /// The brand mark bundled with the app, not fetched — support has no
  /// per-agent photo.
  static const String _logoAsset = 'asset:assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case ConversationKind.support:
        return AppAvatar(name: '', photoUrl: _logoAsset, size: size);
      case ConversationKind.dispute:
        // "!" through the ordinary initials path, per the design's warning
        // treatment for a dispute thread.
        return AppAvatar(name: '!', size: size);
      case ConversationKind.direct:
        final ChatPerson? person = other;
        return person == null
            ? AppAvatar.anonymous(size: size)
            : AppAvatar(
                name: person.name,
                photoUrl: person.avatarUrl,
                size: size,
              );
    }
  }
}

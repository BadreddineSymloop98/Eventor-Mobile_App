import '../../catalog/models/json_read.dart';

/// Who is on the other end of a thread, or one of its participants.
enum ChatRole {
  client,
  provider,
  support;

  /// An unrecognised role reads as [client] — the safest default when a
  /// later role ships and this build has not: no support-only affordance
  /// leaks onto an ordinary person.
  static ChatRole fromApi(String? value) => switch (value) {
        'provider' => ChatRole.provider,
        'support' => ChatRole.support,
        _ => ChatRole.client,
      };
}

/// A person in a conversation — the row's `other`, or one of a detail's
/// `participants`.
class ChatPerson {
  const ChatPerson({
    required this.id,
    required this.name,
    required this.role,
    required this.blocked,
    this.avatarUrl,
  });

  factory ChatPerson.fromJson(Map<String, Object?> json) => ChatPerson(
        id: json['id']! as String,
        name: readString(json, 'name'),
        avatarUrl: readStringOrNull(json, 'avatarUrl'),
        role: ChatRole.fromApi(json['role'] as String?),
        blocked: readBool(json, 'blocked'),
      );

  final String id;
  final String name;
  final String? avatarUrl;
  final ChatRole role;
  final bool blocked;
}

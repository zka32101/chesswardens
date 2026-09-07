/// シェアカード（対局結果の共有用）
class ShareCard {
  final String id;
  final String uid;
  final String matchLogId;
  final String imageUrl;
  final DateTime createdAt;
  final String? caption;

  const ShareCard({
    required this.id,
    required this.uid,
    required this.matchLogId,
    required this.imageUrl,
    required this.createdAt,
    this.caption,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'matchLogId': matchLogId,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'caption': caption,
    };
  }

  factory ShareCard.fromMap(Map<String, dynamic> map) {
    return ShareCard(
      id: map['id'],
      uid: map['uid'],
      matchLogId: map['matchLogId'],
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      caption: map['caption'],
    );
  }
}

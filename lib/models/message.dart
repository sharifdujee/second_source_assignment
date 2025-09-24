import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String chatRoomId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.chatRoomId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.imageUrl,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    try {
      // Debug: Print the raw type value from Firebase
      print("🔍 Raw type from Firebase: '${map['type']}'");

      // Fixed type parsing - compare with just the enum name, not full string
      MessageType parsedType = MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'], // This is the key fix!
        orElse: () {
          print("⚠️ Unknown message type: '${map['type']}', defaulting to text");
          return MessageType.text;
        },
      );

      print("✅ Parsed type: $parsedType");
      print("🖼️ Image URL: ${map['imageUrl']}");

      return MessageModel(
        messageId: map['messageId'] ?? '',
        senderId: map['senderId'] ?? '',
        receiverId: map['receiverId'] ?? '',
        chatRoomId: map['chatRoomId'] ?? '',
        content: map['content'] ?? '',
        type: parsedType,
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        isRead: map['isRead'] ?? false,
        imageUrl: map['imageUrl'],
      );
    } catch (e) {
      print("❌ Error parsing MessageModel: $e, data=$map");
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'chatRoomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last, // This stores 'text' or 'image'
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  // Helper method to check if this is an image message
  bool get isImageMessage => type == MessageType.image && imageUrl != null && imageUrl!.isNotEmpty;

  @override
  String toString() {
    return 'MessageModel(id: $messageId, type: $type, content: $content, imageUrl: $imageUrl)';
  }
}

// Alternative more robust parsing approach
class MessageModelRobust {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String chatRoomId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  MessageModelRobust({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.chatRoomId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.imageUrl,
  });

  factory MessageModelRobust.fromMap(Map<String, dynamic> map) {
    try {
      return MessageModelRobust(
        messageId: map['messageId'] ?? '',
        senderId: map['senderId'] ?? '',
        receiverId: map['receiverId'] ?? '',
        chatRoomId: map['chatRoomId'] ?? '',
        content: map['content'] ?? '',
        type: _parseMessageType(map['type']),
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        isRead: map['isRead'] ?? false,
        imageUrl: map['imageUrl'],
      );
    } catch (e) {
      print("❌ Error parsing MessageModel: $e, data=$map");
      rethrow;
    }
  }

  // Robust type parsing method
  static MessageType _parseMessageType(dynamic typeValue) {
    if (typeValue == null) return MessageType.text;

    String typeString = typeValue.toString().toLowerCase().trim();

    print("🔍 Parsing message type: '$typeString'");

    // Handle various possible formats
    if (typeString == 'image' ||
        typeString == 'messagetype.image' ||
        typeString.endsWith('.image')) {
      print("✅ Parsed as image type");
      return MessageType.image;
    } else {
      print("✅ Parsed as text type");
      return MessageType.text;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'chatRoomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  bool get isImageMessage => type == MessageType.image && imageUrl != null && imageUrl!.isNotEmpty;
}
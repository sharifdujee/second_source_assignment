import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/core/constants/app_color.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_utils.dart';
import '../models/message.dart';


class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final String? otherUserImage; // 👈 pass in the profile image of the other user

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.otherUserImage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment:
      isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        // 👈 Show avatar only for received messages
        if (!isCurrentUser)
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 1),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: otherUserImage != null
                  ? CachedNetworkImageProvider(otherUserImage!)
                  : null,
              child: otherUserImage == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
          ),

        // Bubble + time
        Column(
          crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
                  bottomRight: isCurrentUser
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
                ),
              ),
              child: message.type == MessageType.image &&
                  message.imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              )
                  : Text(
                message.content,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),

            // 👇 Timestamp below bubble
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                AppUtils.formatTimestamp(message.timestamp), // e.g. "just now", "1 min ago"
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


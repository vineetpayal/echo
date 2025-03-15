import 'package:flutter/material.dart';

class Message {
  final String senderId;
  final String senderPhone;
  final String receiverId;
  final String message;
  final int timestamp;
  final bool isRead;
  final String? id;
  final String? chatRoomId;

  Message({
    required this.senderId,
    required this.senderPhone,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.id,
    this.chatRoomId,
  });

  // Convert Message object to JSON for database
  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_phone': senderPhone,
      'receiver_id': receiverId,
      'content': message,
      'timestamp': timestamp,
      'is_read': isRead,
      'chat_room_id': chatRoomId,
    };
  }

  // Create Message object from JSON from database
  factory Message.fromMap(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      senderPhone: json['sender_phone'],
      receiverId: json['receiver_id'],
      message: json['content'],
      timestamp: json['timestamp'],
      isRead: json['is_read'] ?? false,
      chatRoomId: json['chat_room_id'],
    );
  }
}
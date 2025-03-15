import 'package:echo/models/message.dart';
import 'package:echo/models/user.dart' as model;
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient supabaseClient = Supabase.instance.client;

  // Table names
  static const String USERS = "users";
  static const String CHAT_ROOMS = "chat_rooms";
  static const String MESSAGES = "messages";
  static const String PARTICIPANTS = "chat_room_participants";

  //create a chatRoom
  Future<String> createChatRoom(String currentUserId,
      String otherUserId) async {
    //create a chat room id;
    var ids = [currentUserId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");
    final now = DateTime
        .now()
        .millisecondsSinceEpoch;

    //create chatroom in database
    await supabaseClient
        .from(CHAT_ROOMS)
        .insert({'id': chatRoomId, 'created_at': now, 'updated_at': now});

    //Add participants
    await supabaseClient.from(PARTICIPANTS).insert([
      {'chat_room_id': chatRoomId, 'user_id': currentUserId},
      {'chat_room_id': chatRoomId, 'user_id': otherUserId}
    ]);

    return chatRoomId;
  }

  Future<void> sendMessage({required String chatRoomId,
    required String senderId,
    required String senderPhone,
    required String receiverId,
    required String content}) async {
    final timeStamp = DateTime
        .now()
        .millisecondsSinceEpoch;

    Message message = Message(
      chatRoomId: chatRoomId,
        senderId: senderId,
        senderPhone: senderPhone,
        receiverId: receiverId,
        message: content,
        timestamp: timeStamp);

    //insert message into message table
    await supabaseClient.from(MESSAGES).insert(message.toMap());

    //update the last message in chatRoom
    //where id = chatRoomId
    await supabaseClient.from(CHAT_ROOMS).update({
      'last_message': content,
      'last_message_time': timeStamp,
      'updated_at': timeStamp
    }).eq('id', chatRoomId);
  }

  //getChatRoom derails
  Future<List<Map<String, dynamic>>> getChatRooms(String currentUserId) async {
    //get all the chatroom where user is a participant
    final List<dynamic> participatedRooms = await supabaseClient
        .from(PARTICIPANTS)
        .select('chat_room_id')
        .eq('user_id', currentUserId);

    final List<String> roomIds = participatedRooms
        .map((room) => room['chat_room_id'] as String)
        .toList();

    if (roomIds.isEmpty) return [];

    //get chatRoom details
    final response = await supabaseClient
        .from(CHAT_ROOMS)
        .select()
        .inFilter('id', roomIds)
        .order('updated_at', ascending: false);
    return response;
  }

  //fetch all messages in a chatroom
  Future<List<Message>> getMessages(String chatRoomId) async {
    final response = await supabaseClient
        .from(MESSAGES)
        .select()
        .eq('chat_room_id', chatRoomId)
        .order('timestamp', ascending: true);

    return response.map((json) => Message.fromMap(json)).toList();
  }

  //subscribe to messages real time
  void subscribeToMessages(String chatRoomId, Function(Map<String,dynamic>) onMessage) {
    final subscription = supabaseClient
        .from(MESSAGES)
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', chatRoomId)
        .order('timestamp')
        .listen(
          (List<Map<String, dynamic>> data) {
        if (data.isNotEmpty) {
          onMessage(data.first);
        }
      },
    );
  }

  Future<void> markMessageAsRead(String chatRoomId, String receiverId) async {
    await supabaseClient
        .from(MESSAGES)
        .update({'is_read': true})
        .eq('chat_room_id', chatRoomId)
        .eq('receiver_id', receiverId)
        .eq('is_read', false);
  }

  //helper
  Future<String> getOtherParticipantName(String chatRoomId,
      String currentUserId) async {
    // This function would fetch the other participant's name from your users table
    final otherParticipantId =
    await getOtherParticipantId(chatRoomId, currentUserId);
    // Then fetch user details from your users table
    // This is a placeholder - implement according to your user data structure
    final userData = await supabaseClient
        .from(USERS)
        .select('displayName')
        .eq('uid', otherParticipantId)
        .single();
    return userData['displayName'];
  }

  Future<String> getOtherParticipantId(String chatRoomId,
      String currentUserId) async {
    final participants = await supabaseClient
        .from('chat_room_participants')
        .select('user_id')
        .eq('chat_room_id', chatRoomId);

    for (final participant in participants) {
      if (participant['user_id'] != currentUserId) {
        return participant['user_id'];
      }
    }

    throw Exception('No other participant found');
  }

  String formatTimeAgo(int? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<model.User> getOtherUser(String roomId, String currentUserId) async {
    String otherUserId = await getOtherParticipantId(roomId, currentUserId);

    final response = await supabaseClient.from(USERS).select().eq(
        'uid', otherUserId).single();

    return model.User.fromMap(response);
  }
}

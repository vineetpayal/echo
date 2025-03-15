import 'package:echo/models/user.dart' as model;
import 'package:echo/screens/chat_screen.dart';
import 'package:echo/screens/contacts_screen.dart';
import 'package:echo/services/chat_service.dart';
import 'package:echo/services/database_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  String? _currentUserId;
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, model.User> _otherUsers = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Get current user ID with error handling
      _currentUserId = DatabaseService().getCurrentUserId();
      print('Current user ID: $_currentUserId');

      if (_currentUserId == null || _currentUserId!.isEmpty) {
        throw Exception('Failed to get current user ID');
      }

      await _fetchChatRooms();
    } catch (e) {
      print('Initialization error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading conversations: $e';
      });
    }
  }

  Future<void> _fetchChatRooms() async {
    try {
      print('Fetching chat rooms for user: $_currentUserId');
      final chatRooms = await _chatService.getChatRooms(_currentUserId!);
      print('Fetched ${chatRooms.length} chat rooms');

      // Even if we get an empty list, we should update the UI
      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
        _errorMessage = null;
      });

      // Only try to fetch other users if we have chat rooms
      if (chatRooms.isNotEmpty) {
        _setupRealTimeListeners(chatRooms);
        for (final room in chatRooms) {
          _fetchOtherUserForRoom(room['id']);
        }
      }
    } catch (e) {
      print('Error fetching chat rooms: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load conversations';
      });
    }
  }

  // Method specifically for the pull-to-refresh functionality
  Future<void> _handleRefresh() async {
    try {
      final chatRooms = await _chatService.getChatRooms(_currentUserId!);

      if (mounted) {
        setState(() {
          _chatRooms = chatRooms;
          _errorMessage = null;
        });
      }

      // Re-fetch user data and setup listeners
      if (chatRooms.isNotEmpty) {
        _setupRealTimeListeners(chatRooms);
        _otherUsers.clear(); // Clear cached users to refresh all data
        for (final room in chatRooms) {
          _fetchOtherUserForRoom(room['id']);
        }
      }

      return;
    } catch (e) {
      print('Error refreshing chat rooms: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to refresh conversations';
        });
      }
    }
  }

  void _setupRealTimeListeners(List<Map<String, dynamic>> chatRooms) {
    final roomIds = chatRooms.map((room) => room['id'] as String).toList();
    if (roomIds.isNotEmpty) {
      print('Setting up real-time listeners for rooms: $roomIds');
      _chatService.subscribeToChatRoom(roomIds, _handleChatRoomUpdates);
    }
  }

  Future<void> _fetchOtherUserForRoom(String roomId) async {
    try {
      print('Fetching other user for room: $roomId');
      final otherUser = await _chatService.getOtherUser(roomId, _currentUserId!);

      if (mounted) {
        setState(() {
          _otherUsers[roomId] = otherUser;
        });
      }
    } catch (e) {
      print('Error fetching other user for room $roomId: $e');
    }
  }

  void _handleChatRoomUpdates(List<Map<String, dynamic>> updatedRooms) {
    print('Received real-time updates for ${updatedRooms.length} rooms');

    if (!mounted) return;

    for (final updatedRoom in updatedRooms) {
      final index = _chatRooms.indexWhere((room) => room['id'] == updatedRoom['id']);

      if (index != -1) {
        setState(() {
          _chatRooms[index] = updatedRoom;
        });
      } else {
        setState(() {
          _chatRooms.add(updatedRoom);
          _fetchOtherUserForRoom(updatedRoom['id']);
        });
      }
    }

    // Sort rooms by updated_at timestamp
    setState(() {
      _chatRooms.sort((a, b) => (b['updated_at'] ?? 0).compareTo(a['updated_at'] ?? 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversations"),
        elevation: 0,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.chat),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const ContactsScreen(),
          )).then((_) {
            // Refresh chat rooms when returning from contacts
            setState(() {
              _isLoading = true;
            });
            _fetchChatRooms();
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading conversations..."),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchChatRooms();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_chatRooms.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "No conversations yet",
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ContactsScreen(),
                        )).then((_) {
                          _handleRefresh();
                        });
                      },
                      child: const Text("Start a new chat"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          final room = _chatRooms[index];
          final otherUser = _otherUsers[room['id']];
          final lastMessage = room['last_message'] ?? '';
          final lastMessageTime = room['last_message_time'];

          return ListTile(
            leading: Hero(
              tag: "avatar-${room['id']}",
              child: CircleAvatar(
                backgroundImage: otherUser?.profileUrl != null &&
                    otherUser!.profileUrl!.isNotEmpty
                    ? NetworkImage(otherUser.profileUrl!)
                    : const AssetImage('assets/images/profile.png')
                as ImageProvider,
              ),
            ),
            title: Text(
              otherUser?.displayName ?? "Loading...",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _chatService.formatTimeAgo(lastMessageTime),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: room['id'],
                  ),
                ),
              ).then((_) {
                // Refresh chat rooms when returning from chat
                _handleRefresh();
              });
            },
          );
        },
      ),
    );
  }
}
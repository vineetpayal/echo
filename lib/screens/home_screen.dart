import 'package:echo/models/message.dart';
import 'package:echo/screens/chat_screen.dart';
import 'package:echo/screens/contacts_screen.dart';
import 'package:echo/services/chat_service.dart';
import 'package:echo/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chatService = ChatService();
  final currentUserId = DatabaseService().getCurrentUserId();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allChatRooms = [];
  List<Map<String, dynamic>> _filteredChatRooms = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredChatRooms = _allChatRooms;
      });
      return;
    }

    setState(() {
      _filteredChatRooms = _allChatRooms
          .where((room) =>
      (room['other_user_name'] ?? '').toLowerCase().contains(query) ||
          (room['last_message'] ?? '').toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search conversations...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.hintColor),
          ),
          style: theme.textTheme.titleMedium,
          autofocus: true,
        )
            : const Text("Conversations"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 10),
                    Text("Settings")
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 10),
                    Text("Profile")
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              // Handle menu selection
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _chatService.getChatRooms(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't load conversations",
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text("Retry"),
                  )
                ],
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          if (_allChatRooms.isEmpty) {
            _allChatRooms = chatRooms;
            _filteredChatRooms = chatRooms;
          }

          if (_filteredChatRooms.isEmpty && _searchController.text.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No conversations found",
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No conversations yet",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Start a new chat"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ContactsScreen()),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: _filteredChatRooms.length,
            itemBuilder: (context, index) {
              final room = _filteredChatRooms[index];
              final hasUnread = room['unread_count'] != null && room['unread_count'] > 0;

              return _buildChatTile(room, hasUnread, theme);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactsScreen()),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.chat),
        tooltip: "New conversation",
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> room, bool hasUnread, ThemeData theme) {
    return FutureBuilder(
      future: _chatService.getOtherUser(room['id'], currentUserId),
      builder: (context, snapshot) {
        final userName = snapshot.hasData
            ? snapshot.data!.displayName
            : "Loading...";
        final profileUrl = snapshot.hasData ? snapshot.data?.profileUrl : null;

        // Cache the name for searching
        if (snapshot.hasData && room['other_user_name'] == null) {
          room['other_user_name'] = userName;
        }

        return Dismissible(
          key: Key(room['id']),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Delete Conversation"),
                  content: const Text("Are you sure you want to delete this conversation?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("CANCEL"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("DELETE"),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            // Implement delete functionality here
            // _chatService.deleteChatRoom(room['id']);

            setState(() {
              _allChatRooms.removeWhere((r) => r['id'] == room['id']);
              _filteredChatRooms.removeWhere((r) => r['id'] == room['id']);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Conversation deleted"),
                action: SnackBarAction(
                  label: "UNDO",
                  onPressed: () {
                    setState(() {
                      _allChatRooms.add(room);
                      _filterChats();
                    });
                  },
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: hasUnread
                  ? BorderSide(color: theme.colorScheme.primary, width: 1)
                  : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Hero(
                tag: "avatar-${room['id']}",
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: profileUrl != null
                      ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profileUrl,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.person),
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                    ),
                  )
                      : const Icon(Icons.person),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTime(room['last_message_time']),
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnread
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        room['last_message'] ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          color: hasUnread
                              ? theme.textTheme.bodyLarge?.color
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          room['unread_count'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(chatRoomId: room['id']),
                  ),
                ); // Refresh list when returning
              },
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text("Delete conversation"),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement delete
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications_off),
                        title: const Text("Mute notifications"),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement mute
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.archive),
                        title: const Text("Archive conversation"),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement archive
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    final DateTime dateTime = timestamp is DateTime
        ? timestamp
        : DateTime.fromMillisecondsSinceEpoch(timestamp);

    final DateTime now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today: return time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // This week: return day name
      final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older: return date
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
import 'package:echo/models/user.dart';
import 'package:echo/services/chat_service.dart';
import 'package:echo/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool isLoading = false;
  bool isSearching = false;
  List<String> phoneNumbers = [];
  List<User> users = [];

  final DatabaseService databaseService = DatabaseService();
  final ChatService _chatService = ChatService();

  final TextEditingController _searchController = TextEditingController();
  List<User> filteredUsers = [];
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    requestPermissionAndFetchContacts();
    // Live search implementation
    _searchController.addListener(() {
      _filterUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users
          .where((user) => user.displayName.toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        _searchController.clear();
      } else {
        // Focus on search field when search is activated
        FocusScope.of(context).requestFocus(_searchFocusNode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          leading: isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _toggleSearch,
                )
              : null,
          title: isSearching
              ? TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                )
              : const Text("New Chat"),
          actions: [
            if (!isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _toggleSearch,
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchContactsAndFilter,
              tooltip: "Refresh contacts",
            ),
          ],
          elevation: 0,
        ),
        body: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 16),
                    Text("Finding people you can chat with...",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : (_searchController.text.isEmpty ? users : filteredUsers).isEmpty
                ? _buildEmptyState()
                : _buildContactsList(
                    _searchController.text.isEmpty ? users : filteredUsers),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No contacts found on Echo",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _searchController.text.isNotEmpty
                  ? "Try a different search term"
                  : "Invite your friends to join Echo to start chatting",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: fetchContactsAndFilter,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement invite functionality
                },
                icon: const Icon(Icons.share),
                label: const Text("Invite Friends"),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(List<User> userList) {
    return RefreshIndicator(
      onRefresh: fetchContactsAndFilter,
      child: ListView.builder(
        itemCount: userList.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, i) {
          User user = userList[i];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                //TODO - Create a chat room and go back to home screen

              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.2),
                    backgroundImage: user.profileUrl != null
                        ? NetworkImage(user.profileUrl!)
                        : null,
                    child: user.profileUrl == null
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : "?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    user.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: user.statusContent != null &&
                          user.statusContent!.isNotEmpty
                      ? Text(
                          user.statusContent!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        )
                      : null,
                  trailing: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> requestPermissionAndFetchContacts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final status = await FlutterContacts.requestPermission();

      if (status) {
        await fetchContactsAndFilter();
      } else {
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          _showSnackBar(
              "Permission denied. Please allow access to contacts to find friends.",
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString(), isError: true);
      }
      debugPrint("Error in contacts: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.black87,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> fetchContactsAndFilter() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      phoneNumbers.clear(); // Clear previous phone numbers
      for (var contact in contacts) {
        if (contact.phones.isNotEmpty) {
          phoneNumbers.add(contact.phones[0].normalizedNumber);
        }
      }

      users = await databaseService.fetchRegisteredUsers(phoneNumbers,
          onSuccess: (users) {
        filteredUsers = List.from(users);
      }, onFailure: (e) {
        _showSnackBar("Couldn't find contacts: $e", isError: true);
      });

      // Apply any existing filter
      _filterUsers();
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString(), isError: true);
      }
      debugPrint("Error fetching registered users: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

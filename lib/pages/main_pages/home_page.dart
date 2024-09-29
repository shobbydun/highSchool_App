import 'package:ccm/components/drawer_content.dart';
import 'package:ccm/components/event_card.dart';
import 'package:ccm/components/event_details_page.dart';
import 'package:ccm/database/firestore_services.dart';
import 'package:ccm/pages/main_pages/goals_counselling_page.dart';
import 'package:ccm/pages/main_pages/grades_targets_page.dart';
import 'package:ccm/pages/main_pages/notifications_reminders_page.dart';
import 'package:ccm/pages/social_hub/messages_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  final FirestoreServices firestoreServices;

  const HomePage({super.key, required this.firestoreServices});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  String? userName;
  String profileImageUrl = '';
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _fetchUserProfile();
    } else {
      print("No user is currently logged in.");
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final name =
          await widget.firestoreServices.getUsername(user?.email ?? '');
      final imageUrl =
          await widget.firestoreServices.getProfileImageUrl(user?.email ?? '');
      if (mounted) {
        setState(() {
          userName =
              name ?? 'Student'; 
          profileImageUrl =
              imageUrl ?? ''; 
        });
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  String _generateChatRoomId(String currentUserEmail, String recipientEmail) {
    List<String> users = [currentUserEmail, recipientEmail];
    users.sort(); 
    return users.join('_'); 
  }

  List<Widget> _buildScreens() {
    final recipientEmail = 'recipient@example.com'; 
    final recipientUserId = 'recipientUserId'; 
    final chatRoomId = _generateChatRoomId(user?.email ?? '', recipientEmail);

    return [
      HomePageContent(
        userName: userName ?? 'Student',
        firestoreServices: widget.firestoreServices,
      ),
      GradesTargetsPage(
        firestoreServices: widget.firestoreServices,
        navigationSource: 'bottom_nav_bar',
      ),
      GoalsCounsellingPage(),
      MessagesPage(
        chatRoomId: chatRoomId,
        recipientEmail: recipientEmail,
        recipientUserId: recipientUserId,
      ),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home),
        title: "Home",
        activeColorPrimary: Colors.pinkAccent,
        inactiveColorPrimary: Colors.black,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.library_books),
        title: "Grades",
        activeColorPrimary: Colors.pinkAccent,
        inactiveColorPrimary: Colors.black,
        onPressed: (context) {
          _controller.jumpToTab(1); // Navigate to the Grades tab
        },
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.star),
        title: "Goals",
        activeColorPrimary: Colors.pinkAccent,
        inactiveColorPrimary: Colors.black,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.message),
        title: "Messages",
        activeColorPrimary: Colors.pinkAccent,
        inactiveColorPrimary: Colors.black,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.pink[300],
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          "St Annuarite CCM Gatanga",
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications_reminder_page');
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/MainUserProfilePage');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: DrawerContent(
          userEmail: user?.email ?? '',
          firestoreServices: widget.firestoreServices,
        ),
      ),
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(),
        confineToSafeArea: true,
        backgroundColor: Colors.pink[100]!,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        navBarStyle: NavBarStyle.neumorphic,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 10.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
      ),
    );
  }
}


class HomePageContent extends StatefulWidget {
  final String userName;
  final FirestoreServices firestoreServices;

  const HomePageContent({
    super.key,
    required this.userName,
    required this.firestoreServices,
  });

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final PageController _pageController = PageController();
  List<Event> _events = [];
  List<CustomNotification> _notifications = [];
  bool _loadingEvents = true;
  bool _loadingNotifications = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEvents();
    _fetchRecentNotifications();
  }

  Future<void> _fetchUpcomingEvents() async {
    try {
      final events = await widget.firestoreServices.fetchUpcomingEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _loadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingEvents = false;
          _error = 'Failed to load events. Please try again later.';
        });
      }
      print("Error fetching events: $e");
    }
  }

  Future<void> _fetchRecentNotifications() async {
    try {
      final notifications =
          await widget.firestoreServices.fetchRecentNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _loadingNotifications = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingNotifications = false;
          _error = 'Failed to load notifications. Please try again later.';
        });
      }
      print("Error fetching notifications: $e");
    }
  }

  void _onNotificationTap(CustomNotification notification) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationsRemindersPage(),
      ),
    );
  }

  void _onEventCardTap(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(event: event),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingEvents || _loadingNotifications) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi ${widget.userName.toUpperCase()}!",
            style: TextStyle(
              color: Colors.pink[800],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Upcoming Events",
            style: TextStyle(
              color: Colors.pink[800],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 350,
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  children: _events
                      .map((event) => EventCard(
                            imagePath: event.imagePath,
                            title: event.title,
                            date: event.date,
                            onTap: () => _onEventCardTap(event),
                          ))
                      .toList(),
                ),
                Positioned(
                  left: 0,
                  top: 180,
                  child: IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () => _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 180,
                  child: IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () => _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Recent Notifications",
            style: TextStyle(
              color: Colors.pink[800],
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _notifications.isEmpty
                  ? [Text('No recent notifications available.')]
                  : _notifications
                      .map((notification) => ListTile(
                            leading: Icon(Icons.notifications_none_sharp,
                                color: Colors.pink[600]),
                            title: Text(notification.title),
                            subtitle: Text(notification.date
                                .toDate()
                                .toLocal()
                                .toString()
                                .split(' ')[0]), // Display date only
                            onTap: () => _onNotificationTap(notification),
                          ))
                      .toList(),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

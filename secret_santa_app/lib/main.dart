import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() {
  runApp(const SecretSantaApp());
}

class SecretSantaApp extends StatelessWidget {
  const SecretSantaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SecretSantaAppState>(
      create: (context) => SecretSantaAppState(),
      child: MaterialApp(
        title: 'Secret Santa App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const MainPage(title: 'Secret Santa App'),
      ),
    );
  }
}

class SecretSantaAppState extends ChangeNotifier {
  final List<ExchangeGroup> _exchangeGroups = [];

  void addGroup(ExchangeGroup group) {
    _exchangeGroups.add(group);
    notifyListeners();
  }

  List<ExchangeGroup> get groups => _exchangeGroups;

}

class ExchangeGroup {
  String name;
  List<String> participants;
  Map<String, Set<String>> restrictions;
  Map<String, String> santaPairs;

  ExchangeGroup(this.name, this.participants, this.restrictions)
    : santaPairs = {} {
      generateSantaPairs();
    }

  // Method to generate random Santa pairs
  void generateSantaPairs() {
    List<String> availableGiftees = List.from(participants);
    Random random = Random();

    for (var gifter in participants) {
      List<String> validGiftees = availableGiftees.where((giftee) {
      return giftee != gifter &&
          !(restrictions[gifter]?.contains(giftee) ?? false);
      }).toList();

      if (validGiftees.isEmpty) {
        throw Exception('Unable to assign a valid giftee for $gifter.');
      }
      String giftee = validGiftees[random.nextInt(validGiftees.length)];

      // Assign the pair and remove the giftee from the pool
      santaPairs[gifter] = giftee;
      availableGiftees.remove(giftee);
    }
  }
}


class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
    int _currentIndex = 0;

    final List<Widget> _pages = [
        ExchangeGroupsPage(),
        CreateGroupPage(),
    ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Exchanges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create Exchange',
          ),
        ],
      ),
    );
  }
}

class ExchangeGroupsPage extends StatelessWidget {
  const ExchangeGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<SecretSantaAppState>();

    final List<ExchangeGroup> groups = appState.groups;
    return Scaffold(
      appBar: AppBar(title: Text('Exchanges')),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(groups[index].name),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Navigate to the Group Details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailsPage(group: groups[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final List<TextEditingController> _participantControllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; ++i) {
      _participantControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _participantControllers) {
      controller.dispose();
    }
    _groupNameController.dispose();
    super.dispose();
  }

  // Function to check if the second last two controllers has input and add more controllers
  void _checkSecondLastControllerInput() {
    if (_participantControllers[_participantControllers.length - 1].text.isNotEmpty 
      && _participantControllers[_participantControllers.length - 2].text.isNotEmpty) {
      setState(() {
        _participantControllers.add(TextEditingController());
      });
    }
  }

  // Function to get all participants' text
  List<String> getParticipantNames() {
    return _participantControllers
        .map((controller) => controller.text)  // Get the text of each controller
        .where((text) => text.isNotEmpty)  // Exclude empty text fields
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<SecretSantaAppState>();

    // Listen for changes in the two last controllers
    if (_participantControllers.length >= 3) {
      _participantControllers[_participantControllers.length - 1]
          .addListener(_checkSecondLastControllerInput);
      _participantControllers[_participantControllers.length - 2]
          .addListener(_checkSecondLastControllerInput);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Create Exchange')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Exchange Name',
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: List.generate(_participantControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: _participantControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Participant ${index + 1}',
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  appState.addGroup(ExchangeGroup(_groupNameController.text, getParticipantNames(), {}));
                },
                child: Text('Create Exchange'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupDetailsPage extends StatelessWidget {
  const GroupDetailsPage({super.key, required this.group});

  final ExchangeGroup group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: ListView.builder(
        itemCount: group.participants.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(group.participants[index]),
            trailing: Icon(Icons.arrow_forward),
            contentPadding: EdgeInsets.all(16.0),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("${group.participants[index]}'s secret santa is:"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Text("${group.santaPairs[group.participants[index]]}"))
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Close the dialog
                        child: Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
      )
    );
  }
}

class MyFragment extends StatelessWidget {
  final String title;

  MyFragment({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class SpecifyRestrictionsPage extends StatelessWidget {
  SpecifyRestrictionsPage({super.key, required this.groupName});

  final String groupName;


  final List<String> participants = ['Alice', 'Bob', 'Charlie', 'Diana'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restrictions - $groupName')),
      body: ListView.builder(
        itemCount: participants.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Who should ${participants[index]} not get?'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Add logic to configure restrictions
            },
          );
        },
      ),
    );
  }
}

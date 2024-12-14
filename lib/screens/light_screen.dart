import 'package:flutter/material.dart';

class LightScreen extends StatefulWidget {
  const LightScreen({super.key});

  @override
  _LightScreenState createState() => _LightScreenState();
}

class _LightScreenState extends State<LightScreen> {
  List<Map<String, dynamic>> switches = [];
  List<int> availableSwitches = List.generate(16, (index) => index); // 0-15 switch numbers

  @override
  void initState() {
    super.initState();
    _loadSwitches(); // Load switches from a database or API
  }

  Future<void> _loadSwitches() async {
    // Simulate fetching from a database or API
    setState(() {
      switches = [
        {'room': 'Living Room', 'switchNumber': 1, 'state': false},
        {'room': 'Bedroom', 'switchNumber': 2, 'state': true},
      ];
      // Remove already assigned switches
      for (var s in switches) {
        availableSwitches.remove(s['switchNumber']);
      }
    });
  }

  Future<void> _saveSwitches() async {
    // Simulate saving to a database or API
    print('Saving switches: $switches');
  }

  void _addSwitch() {
    String? roomName;
    int? switchNumber;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Switch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Room Name'),
                onChanged: (value) {
                  roomName = value;
                },
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Switch Number'),
                items: availableSwitches
                    .map((num) => DropdownMenuItem<int>(
                  value: num,
                  child: Text(num.toString()),
                ))
                    .toList(),
                onChanged: (value) {
                  switchNumber = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (roomName != null && switchNumber != null) {
                  setState(() {
                    switches.add({'room': roomName, 'switchNumber': switchNumber, 'state': false});
                    availableSwitches.remove(switchNumber);
                  });
                  _saveSwitches();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _toggleSwitch(int index) async {
    setState(() {
      switches[index]['state'] = !switches[index]['state'];
    });
    await _saveSwitches();
  }

  void _deleteSwitch(int index) async {
    setState(() {
      availableSwitches.add(switches[index]['switchNumber']);
      switches.removeAt(index);
    });
    await _saveSwitches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Villanykörte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSwitch,
          ),
        ],
      ),
      body: switches.isEmpty
          ? const Center(child: Text('No switches added.'))
          : ListView.builder(
        itemCount: switches.length,
        itemBuilder: (context, index) {
          final switchItem = switches[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Text(
                switchItem['room'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              title: Text(
                'Switch ${switchItem['switchNumber']}',
                style: const TextStyle(fontSize: 16),
              ),
              trailing: GestureDetector(
                onTap: () => _toggleSwitch(index),
                child: Icon(
                  Icons.lightbulb,
                  size: 30,
                  color: switchItem['state'] ? Colors.yellow : Colors.grey,
                ),
              ),
              onLongPress: () => _deleteSwitch(index),
            ),
          );
        },
      ),
    );
  }
}

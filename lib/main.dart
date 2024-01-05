import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://aobokydqiibdnwdhwedm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvYm9reWRxaWliZG53ZGh3ZWRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQzMTA3NDYsImV4cCI6MjAxOTg4Njc0Nn0.IRo0NSwHBQI9lavKTBW45DZz9MVFXxWFiMtMUZ4MFiw',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Stream<List<Map<String, dynamic>>> _gameStream;

  @override
  void initState() {
    super.initState();
    _gameStream = Supabase.instance.client.from('game_results').stream(
      primaryKey: ['id'],
    );
  }

void _addGame() {
  String selectedGame = ''; // Selected game (either from dropdown or custom input)
  bool useDropdown = true; // Flag to track whether to use the dropdown or custom input
  String customGame = '';
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Add Game and Winner'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Radio(
                      value: true,
                      groupValue: useDropdown,
                      onChanged: (bool? value) {
                        setState(() {
                          useDropdown = true;
                          customGame ='';
                        });
                      },
                    ),
                    Text('Select from Dropdown'),
                    Radio(
                      value: false,
                      groupValue: useDropdown,
                      onChanged: (bool? value) {
                        setState(() {
                          useDropdown = false;
                        });
                      },
                    ),
                    Text('Enter Custom Game'),
                  ],
                ),
                SizedBox(height: 10),
                if (useDropdown)
                  FutureBuilder<List<String>>(
                    future: _fetchGames(),
                    builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error fetching games: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No games found.');
                      } else {
                        return DropdownButtonFormField<String>(
                          value: selectedGame.isNotEmpty ? selectedGame : snapshot.data!.first,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedGame = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a game name';
                            }
                            return null;
                          },
                          items: snapshot.data!.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        );
                      }
                    },
                  )
                else
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Custom Game Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      customGame = value;
                    },
                    validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a game name';
                        }
                        return null;
                      },
                  ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                         if(customGame != '')
                        {
                          selectedGame = customGame;
                        }
                        _saveGame('Clay', selectedGame);
                        Navigator.pop(context);
                      },
                      child: Text('Clay Won'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                         if(customGame != '')
                        {
                          selectedGame = customGame;
                        }
                        _saveGame('Levi', selectedGame);
                        Navigator.pop(context);
                      },
                      child: Text('Levi Won'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}



Future<List<String>> _fetchGames() async {
  final gamesSnapshot = await _gameStream.first;

  if (gamesSnapshot.isEmpty) {
    return []; // Return an empty list if no data is available
  }

  // Extracting game names from the snapshot
  Set<String> gameNames = {};
  for (var gameData in gamesSnapshot) {
    String gameName = gameData['game'] as String;
    gameNames.add(gameName);
  }

  return gameNames.toList(); // Return list of game names
}


  void _refreshTable() {
    _gameStream = Supabase.instance.client.from('game_results').stream(
      primaryKey: ['id'],
    );
    setState(() {});
  }

  void _saveGame(String winner, String game) async {
    await Supabase.instance.client.from('game_results').insert({
      'game': game,
      'winner': winner,
      'timestamp': DateTime.now().toUtc().toIso8601String()
    });
    _refreshTable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text(widget.title),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _gameStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final games = snapshot.data!;
          Map<String, Map<String, int>> summary = {};

          for (var game in games) {
            String winner = game['winner'];
            String gameName = game['game'];

            summary.putIfAbsent(gameName, () => {});
            summary[gameName]!.update(winner, (value) => value + 1,
                ifAbsent: () => 1);
          }

          List<DataColumn> columns = [];
          List<DataRow> rows = [];

          Set allWinners = games.map((game) => game['winner']).toSet();

          // Create columns
          columns.add(DataColumn(
            label: Text('Game'),
            numeric: false,
          ));
          allWinners.forEach((winner) {
            columns.add(DataColumn(
              label: Text('$winner Wins'),
              numeric: true,
            ));
          });

          // Create rows
          summary.forEach((game, winnersWon) {
            List<DataCell> cells = [];
            cells.add(DataCell(Text(game)));

            allWinners.forEach((winner) {
              int count = winnersWon.containsKey(winner) ? winnersWon[winner]! : 0;
              cells.add(DataCell(Text('$count')));
            });
            rows.add(DataRow(cells: cells));
          });

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: rows,
              columnSpacing: 8.0,
              horizontalMargin: 8.0,
              headingRowColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  return Theme.of(context).colorScheme.primary.withOpacity(0.3);
                },
              ),
              dataRowColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  return Theme.of(context).colorScheme.primary.withOpacity(0.1);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGame,
        tooltip: 'Add Game',
        child: const Icon(Icons.add),
      ),
    );
  }
}

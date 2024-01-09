
import 'package:auto_size_text/auto_size_text.dart';
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
      title: 'Clay Vs Levi',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(brightness: Brightness.dark,  primary: Colors.blueGrey, secondary: Colors.grey),
        textTheme: TextTheme(
          bodyLarge: TextStyle(),
          bodyMedium: TextStyle(), 
          bodySmall: TextStyle(),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
           
          
          
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Clay Vs Levi'),
    );
  }
}
enum FilterType {
  ThisWeek,
  ThisDay,
  ThisMonth,
  AllTime,
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Stream<List<Map<String, dynamic>>> _gameStream;
  FilterType _selectedFilter = FilterType.AllTime; // Track the selected filter type
  bool _showAllGames = false; // Track whether to show all games or not
  

  //Functions

  List<Map<String, dynamic>> filterGames(List<Map<String, dynamic>> games, FilterType filter) {
    // Implement your filtering logic here based on the timestamp or other criteria
    // For demonstration, let's assume it filters games based on timestamps (replace this with your actual logic)
    DateTime now = DateTime.now();
    switch (filter) {
      case FilterType.ThisWeek:
        DateTime weekAgo = now.subtract(Duration(days: 7));
        return games.where((game) => DateTime.parse(game['timestamp']).isAfter(weekAgo)).toList();
      case FilterType.ThisDay:
        DateTime startOfDay = DateTime(now.year, now.month, now.day);
        return games.where((game) => DateTime.parse(game['timestamp']).isAfter(startOfDay)).toList();
      case FilterType.ThisMonth:
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        return games.where((game) => DateTime.parse(game['timestamp']).isAfter(startOfMonth)).toList();
      case FilterType.AllTime:
        return games;
    }
  }

@override
  void initState() {
      super.initState();
      _gameStream = Supabase.instance.client.from('game_results').stream(
        primaryKey: ['id'],
      );
 
  }
      

  

      // Subscribe to changes in the 'game_results' table
      

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
                  Wrap(
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
                        ],
                      ),
                      Row(
                        children: [
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

                        ]
                      )
                      
                    ],
                  ),
                  SizedBox(height: 10),
                  if (useDropdown)
                    FutureBuilder<List<String>>(
                      future: _fetchGames(),
                      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } 
                        else if (snapshot.hasError) {
                          return Text('Error fetching games: ${snapshot.error}');
                        } 
                        else if (snapshot.data == null || snapshot.data!.isEmpty) {
                          return Text('No games found.');
                        } 
                        else {
                          final games = snapshot.data!; // Get the list of games
                          String initialGame = games.firstWhere((game) => game.isNotEmpty, orElse: () => '');
                          if(selectedGame == '')
                          {
                            selectedGame = initialGame;
                          } // Find the first non-empty game name
                          return DropdownButtonFormField<String>(
                            value: selectedGame.isNotEmpty ? selectedGame : initialGame,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedGame = newValue ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a game name';
                              }
                              return null;
                            },
                            items: games.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          
                          );
                        }
                      }

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

  

  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  void _saveGame(String winner, String game) async {
  await Supabase.instance.client.from('game_results').insert({
    'game': game,
    'winner': winner,
    'timestamp': DateTime.now().toUtc().toIso8601String()
  });
}

  double calculateFontSize(double screenWidth, double minBreak, double minSize, double maxSize, double fontSize) {
  double desiredFontSize = fontSize;
  if (screenWidth < minBreak) {
    desiredFontSize = minSize;
  }
  else if(fontSize > maxSize)
  {
    desiredFontSize = maxSize;
  }
  return desiredFontSize;
}

  @override
  Widget build(BuildContext context) {

    //Variables
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double minBreak = 625; // Define your maximum width here
    double bodyFontSize = calculateFontSize(screenWidth, minBreak, 16, 25, screenWidth * 0.02); // Set your desired font size
    double headingFontSize = calculateFontSize(screenWidth, minBreak, 20, 30, screenWidth * 0.025); // Set your desired font size
    double titleFontSize = calculateFontSize(screenWidth, minBreak, 25, 50, screenWidth * 0.04); // Set your desired font size


    //Main Build
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.1,
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Text(
          widget.title,
          style: TextStyle(fontSize: titleFontSize)
        ),
      ),
      body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        gameBreakdownWidget(),
        Expanded(
          child:StreamBuilder<List<Map<String, dynamic>>>(
            stream: _gameStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              // Apply filtering logic to the received game data based on the selected filter
              List<Map<String, dynamic>> filteredGames = filterGames(snapshot.data!, _selectedFilter);
              final games = filteredGames;
              Map<String, Map<String, int>> summary = {};

              for (var game in games) {
                String winner = game['winner'];
                String gameName = game['game'];

                summary.putIfAbsent(gameName, () => {});
                summary[gameName]!.update(winner, (value) => value + 1,
                    ifAbsent: () => 1);
              }

              List<DataColumn> columns = [];

              Set allWinners = games.map((game) => game['winner']).toSet();

              // Create columns
              columns.add(DataColumn(
                label: Text(
                  'Game',
                  style: TextStyle(fontSize: headingFontSize, fontWeight: FontWeight.bold)
                ),
                numeric: false,
              ));
              allWinners.forEach((winner) {
                columns.add(DataColumn(
                  label: Text(
                    '$winner',
                    style: TextStyle(fontSize: headingFontSize, fontWeight: FontWeight.bold)
                  ),
                  numeric: true,
                ));
              });

             Map<String, Map<String, int>> totalWins = {}; // Initialize total wins for each game and each winner
      Map<String, int> grandTotal = {}; // Initialize grand total count for each winner

      // Calculate total wins for each game and each winner
      summary.forEach((game, winnersWon) {
        winnersWon.forEach((winner, count) {
          totalWins.putIfAbsent(game, () => {});
          totalWins[game]!.update(winner, (value) => value + count, ifAbsent: () => count);

          grandTotal.update(winner, (value) => value + count, ifAbsent: () => count);
        });
      });

      List<DataRow> totalRows = [];

      // Create rows for individual game totals
      totalWins.forEach((game, winnersWon) {
        List<DataCell> cells = [];
        cells.add(DataCell(Text(game, style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.bold))));
        
        allWinners.forEach((winner) {
          int count = winnersWon.containsKey(winner) ? winnersWon[winner]! : 0;
          cells.add(DataCell(Text('$count', style: TextStyle(fontSize: bodyFontSize))));
        });
        totalRows.add(DataRow(cells: cells));
      });

      // Add a row for the Grand Total
      List<DataCell> grandTotalCells = [];
      grandTotalCells.add(DataCell(Text('Grand Total', style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.bold))));
      
      allWinners.forEach((winner) {
        int count = grandTotal.containsKey(winner) ? grandTotal[winner]! : 0;
        grandTotalCells.add(DataCell(Text('$count', style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.bold))));
      });

      totalRows.add(DataRow(cells: grandTotalCells));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            
                    ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth*0.05),
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columns: columns,
                            rows: totalRows,
                            headingTextStyle: Theme.of(context).textTheme.displaySmall!,
                            dataTextStyle: Theme.of(context).textTheme.displaySmall!,
                            columnSpacing: screenWidth*0.15,
                            horizontalMargin: 8.0,
                            
                            
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ExpansionTile(
                      title: Text(
                        'All Games',
                        style: TextStyle(fontSize: headingFontSize, fontWeight: FontWeight.bold )
                        ),
                      
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _showAllGames = expanded;
                        });
                      },
                      children: <Widget>[
                      if (_showAllGames)
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width, // Adjust the maximum height as needed
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,

                            child: SizedBox(
                              height: (MediaQuery.of(context).size.height * 0.3), // Set the desired height
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  DataTable(
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'Winner',
                                          style: TextStyle(fontSize: bodyFontSize)
                                        )
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Game',
                                          style: TextStyle(fontSize: bodyFontSize)
                                        )
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Timestamp',
                                          style: TextStyle(fontSize: bodyFontSize)
                                        )
                                      ),
                                    ],
                                    rows: filteredGames
                                      .where((game) => game['timestamp'] != null)
                                      .toList()
                                      .reversed  // Reverse the list to display the most recent timestamp first
                                      .map((game) {
                                    final timestamp = DateTime.parse(game['timestamp']).toLocal();
                                    final formattedTimestamp =
                                        '${timestamp.year}-${_twoDigits(timestamp.month)}-${_twoDigits(timestamp.day)} ${_twoDigits(timestamp.hour)}:${_twoDigits(timestamp.minute)}';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              game['winner'],
                                              style: TextStyle(fontSize: bodyFontSize)
                                            )
                                          ),
                                          DataCell(
                                            Text(
                                              game['game'],
                                              style: TextStyle(fontSize: bodyFontSize)
                                            )
                                          ),
                                          DataCell(
                                            Text(
                                              formattedTimestamp,
                                              style: TextStyle(fontSize: bodyFontSize)
                                            )
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  
                ],                 
              );
            },
          ),         
        )
      ],
    ),
      
    floatingActionButton: FloatingActionButton(
      onPressed: _addGame,
      tooltip: 'Add Game',
      child: const Icon(Icons.add),
    ),
    );
  }
  
  
  //Custom Widgets
  Widget _buildFilters() {
    return Expanded(
      child: Wrap(
        spacing: MediaQuery.of(context).size.width * 0.05,
        children: [
          filterOptionWidget('All Time', FilterType.AllTime),
          filterOptionWidget('This Month', FilterType.ThisMonth),
          filterOptionWidget('This Week', FilterType.ThisWeek),
          filterOptionWidget('Today', FilterType.ThisDay),
        ],
        
      )    
    );
  }

  Widget filterOptionWidget(String text, FilterType value) {
     double screenWidth = MediaQuery.of(context).size.width;
    double minBreak = 625; // Define your maximum width here
    double headingFontSize = calculateFontSize(screenWidth, minBreak, 8, 30, screenWidth * 0.025); // Set your desired font size

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio(
          value: value,
          groupValue: _selectedFilter,
          onChanged: (FilterType? selectedValue) {
            setState(() {
              _selectedFilter = selectedValue!;
              // Implement filtering logic based on the selected filter value
            });
          },
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: headingFontSize
          )
        ),
      ],
    );
  }

  Widget gameBreakdownWidget()
  {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double minBreak = 625; // Define your maximum width here
    double headingFontSize = calculateFontSize(screenWidth, minBreak, 20, 30, screenWidth * 0.025); // Set your desired font size


    if (screenWidth < 625) 
    {
      // Display as a Column on smaller screens (e.g., phones)
      return SizedBox(
        height: screenHeight * 0.125,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              SizedBox(
                height: screenHeight * 0.075,
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    'Game Breakdown',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: headingFontSize, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              SizedBox(
                height: screenHeight * 0.05,
                child: Center(child: _buildFilters(),)
                
              )
            ],
          ),
        )      
      );   
    } 
    else 
    {
      // Display as a Row on larger screens (e.g., tablets, desktops)
      return
      SizedBox(
        height: screenHeight * 0.075,
        child: Container(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex:1,
                child: Container(
                  child: Center(
                    child: AutoSizeText(
                    'Game Breakdown',
                    style: TextStyle(fontSize: headingFontSize, fontWeight: FontWeight.bold),
                    ) 
                  )
                ),
              ),
              Expanded(
                flex:3,
                child: Container(
                  child: Center(
                    child: _buildFilters() 
                  )
                ),
              ),
              
            ],
          ),
        ),

      );
      
    }
  }
}


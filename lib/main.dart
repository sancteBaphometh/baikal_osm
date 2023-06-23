import 'package:baikal_osm/map.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Path {
  final int id;
  final String title;
  final String description;
  final double start_long;
  final double start_lat;
  final double end_long;
  final double end_lat;

  Path(this.id, this.title, this.description, this.start_long, this.start_lat,
      this.end_long, this.end_lat);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_long': start_long,
      'start_lat': start_lat,
      'end_long': end_long,
      'end_lat': end_lat,
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Взаимодействие с базой данных идёт только в методе main,
  // соответственно, если нужно где-то в коде вызвать методы
  // базы данных, то придётся
  // TODO переделать логику взаимодействия с БД через класс DB

  final database = openDatabase(
    join(await getDatabasesPath(), 'dbpath.db'),

    onCreate: (db, version) {
      return db.execute(
        """
        CREATE TABLE paths(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        title TEXT,
        description TEXT,
        start_long DOUBLE,
        start_lat DOUBLE,
        end_long DOUBLE,
        end_lat DOUBLE
        )
        """,
      );
    },
    version: 1,
  );

  Future<void> insertPath(Path path) async {
    final db = await database;

    await db.insert(
      'paths',
      path.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Path>> paths() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('paths');

    return List.generate(maps.length, (i) {
      return Path(
          maps[i]['id'],
          maps[i]['title'],
          maps[i]['description'],
          maps[i]['start_long'],
          maps[i]['start_lat'],
          maps[i]['end_long'],
          maps[i]['end_lat']
      );
    });
  }

  Future<void> updatePath(Path path) async {
    final db = await database;

    await db.update(
      'paths',
      path.toMap(),
      where: 'id = ?',
      whereArgs: [path.id],
    );
  }

  Future<void> deletePath(int id) async {
    final db = await database;

    await db.delete(
      'paths',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  runApp(
    MaterialApp(
      title: 'Passing Data',
      home: PathsScreen(
          paths: await paths()
      ),
    ),
  );
}

class DB {
  static final DB instance = DB._init();

  static Database? _database;

  DB._init();
}

class PathsScreen extends StatelessWidget {
  const PathsScreen({super.key, required this.paths});

  final List<Path> paths;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paths List'),
      ),
      body: ListView.builder(
        itemCount: paths.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(paths[index].title),
            // When a user taps the ListTile, navigate to the DetailScreen.
            // Notice that you're not only creating a DetailScreen, you're
            // also passing the current path through to it.
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(path: paths[index]),
                ),
              );
            },
            onLongPress: () async {
              await showMenu(
                  context: context,
                  position: RelativeRect.fromRect(
                      Rect.fromLTWH(150, 235, 20, 20),
                      Rect.fromLTWH(0, 0, 100, 30),
                  ),
                  items: [
                    const PopupMenuItem(child: Text("Удалить"))
              ]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(title: "Baikal OSM App")));
          },
        child: const Icon(Icons.map),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  // In the constructor, require a Path.
  const DetailScreen({super.key, required this.path});

  // Declare a field that holds the Path.
  final Path path;

  @override
  Widget build(BuildContext context) {
    // Use the Path to create the UI.
    return Scaffold(
      appBar: AppBar(
        title: Text(path.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Text(path.description),
                ),
                const Text(
                  "Координаты начала пути:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${path.start_lat}_${path.start_long}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const Text(
                  "Координаты конца пути:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${path.end_lat}_${path.end_long}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            SizedBox(
              width: 400,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(title: "Baikal OSM App")));
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  elevation: 5,
                  padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                ),
                child: const Text(
                  "Отобразить маршрут на карте",
                  style: TextStyle(fontSize: 18),)
              )
            )
          ],
        )
      ),
    );
  }
}

// Edit path to save it in DB
class EditPath extends StatelessWidget {
  // In the constructor, require a Path.
  EditPath({super.key, required this.path});

  // Declare a field that holds the Path.
  final Path path;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void dispose() {
    // Clean up the controller when the widget is disposed.
    titleController.dispose();
    descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the Path to create the UI.
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Path"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Введите название маршрута',
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextField(
                    controller: descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Введите описание',
                    ),
                  ),
                ),
                const Text(
                    "Координаты начала пути:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    "${path.start_lat}_${path.start_long}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const Text(
                  "Координаты конца пути:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${path.end_lat}_${path.end_long}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    elevation: 5,
                    padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                ),
                child: const Text(
                  "Сохранить маршрут",
                  style: TextStyle(fontSize: 18),)
            )
          ],
        )
      ),
    );
  }
}
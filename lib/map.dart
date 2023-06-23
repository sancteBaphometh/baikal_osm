import 'package:baikal_osm/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          splashColor: Colors.white,
        ),
        //useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Baikal OSM App',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required String title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _mapController = MapController(initMapWithUserPosition: true);

  var marks = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      _mapController.listenerMapSingleTapping.addListener(() async {

        // When tap on map we will add a new marker
        var position = _mapController.listenerMapSingleTapping.value;

        if (position != null) {
          await _mapController.addMarker(position, markerIcon: const MarkerIcon(
            icon: Icon(Icons.pin_drop, color: Colors.blue, size: 50,),
          ));

          // Add Marker to map, for hold information on marker in case
          // we want to use it
          var key = '${position.latitude} ${position.longitude}';

          marks.add(GeoPoint(latitude: position.latitude, longitude: position.longitude));

          print(marks);
        }
      });
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void setLayerCallback (tile) async {
    await _mapController.changeTileLayer(tileLayer: tile);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Baikal OSM App"),
        actions: [
          // Make a route button
          IconButton(
              onPressed: () async {
                _mapController.drawRoad(
                  marks[0],
                  marks[1],
                  roadType: RoadType.foot,
                  roadOption: const RoadOption(
                    roadWidth: 10,
                    roadColor: Colors.blue,
                    zoomInto: true,
                  ),
                );
              },
              icon: const Icon(Icons.route_outlined))
        ],
      ),

      body: OSMFlutter(
        controller: _mapController,
        mapIsLoading: const Center(child: CircularProgressIndicator(),),
        trackMyPosition: true,
        initZoom: 12,
        minZoomLevel: 4,
        maxZoomLevel: 16,
        stepZoom: 1.0,
        androidHotReloadSupport: true,


        userLocationMarker: UserLocationMaker(

          personMarker: const MarkerIcon(
            icon: Icon(Icons.person_pin_circle_outlined, color: Colors.red, size: 50)
          ),

          directionArrowMarker: const MarkerIcon(
              icon: Icon(Icons.location_on, color: Colors.black, size: 50)
          ),

        ),

        roadConfiguration: const RoadOption(roadColor: Colors.blueGrey),
        markerOption: MarkerOption(
          defaultMarker: const MarkerIcon(
            icon: Icon(Icons.person_pin_circle, color: Colors.black, size: 50)
          )
        ),

        onMapIsReady: (isReady) async {
          if (isReady) {
            await Future.delayed(Duration(seconds: 1), () async{
              await _mapController.currentLocation();
            });
          }
        },

        onGeoPointClicked: (geoPoint) {
          var key = '${geoPoint.latitude}_${geoPoint.longitude}';
          // When user click to a marker
          showModalBottomSheet(context: context, builder: (context){
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Mark',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue
                        ),),
                        const Divider(thickness: 1,),
                        Text(
                          key,
                        ),
                        // Delete path button
                        // Also delete the marks
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                  onPressed: () async {
                                    marks.clear();
                                    await _mapController.removeLastRoad();
                                    await _mapController.removeMarker(geoPoint);
                                  },
                                  icon: Icon(Icons.delete)),

                              IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(builder:
                                            (context) => EditPath(path: Path(
                                                0,
                                                "",
                                                "",
                                                marks[0].longitude,
                                                marks[0].latitude,
                                                marks[1].longitude,
                                                marks[1].latitude
                                            ))));
                                  },
                                  icon: const Icon(Icons.add)),
                            ]
                        )
                      ],
                    ),),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.clear),
                    )
                  ],
                ),
              ),
            );
          });
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 30),
                  FloatingActionButton(
                    heroTag: 'btn1',
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          bottomLeft: Radius.circular(30.0)
                        )
                    ),
                    onPressed: () {
                      setLayerCallback(CustomTile.publicTransportationOSM());
                    },
                    child: Icon(Icons.train_outlined),
                  ),
                  FloatingActionButton(
                    heroTag: 'btn2',
                    elevation: 0,
                    shape: BeveledRectangleBorder(),
                    onPressed: () {
                      setLayerCallback(CustomTile.cycleOSM());
                    },
                    child: Icon(Icons.forest_outlined),
                  ),
                  FloatingActionButton(
                    heroTag: 'btn3',
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0)
                        )
                    ),
                    onPressed: () {
                      setLayerCallback(null);
                    },
                    child: Icon(Icons.maps_home_work_outlined),
                  ),
                ]
              ),
              FloatingActionButton(
                heroTag: 'btn4',
                elevation: 0,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.format_list_bulleted_outlined),
              ),
            ],
          ),
        ),
    );
  }
}
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as loc;
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:pknu/constants.dart'; // Ensure this contains your GOOGLE_MAP_API_KEY
import 'package:google_places_flutter/model/prediction.dart';

class MapPage extends StatefulWidget {
  static const String id = 'map_page';
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  loc.Location _locationController = loc.Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  LatLng? _currentP;
  LatLng? _selectedLocation; // This will hold the selected location
  // bool _isCameraFollowing = true; // Flag to control camera movement
  Map<PolylineId, Polyline> polylines = {};
  Set<Circle> circles = {}; // For showing a blue circle around current location
  String? _distance = "Unknown"; // To store distance
  String? _duration = "Unknown"; // To store duration

  List<String> _filteredLocations = [];
  final TextEditingController _searchController =
      TextEditingController(); // Added controller

  final Map<String, LatLng> _locationMap = {
    "A11 대학본부": LatLng(35.134032, 129.1031735),
    "A12 웅비관": LatLng(35.13451, 129.1029),
    "A13 누리관": LatLng(35.13483, 129.1031),
    "A15 향파관": LatLng(35.13533, 129.1030),
    "A21 미래관": LatLng(35.13402, 129.1021),
    "A22 디자인관": LatLng(35.13429, 129.1015),
    "A23 나래관": LatLng(35.13489, 129.1018),
    "B11 위드센터": LatLng(35.13404, 129.1056),
    "B12 나비센터": LatLng(35.13410, 129.1063),
    "B13 충무관": LatLng(35.13507, 129.1051),
    "B14 환경해양관": LatLng(35.13510, 129.1062),
    "B15 자연과학 1관": LatLng(35.13561, 129.1056),
    "B21 가온관": LatLng(35.13404, 129.1048),
    "B22 청운관": LatLng(35.13448, 129.1048),
    "C11 수산질병관리원": LatLng(35.13379, 129.1086),
    "C12 장영실관": LatLng(35.13478, 129.1089),
    "C13 해양공동연구관": LatLng(35.13539, 129.1090),
    "C14 어린이집": LatLng(35.13496, 129.1095),
    "C21 수산과학관": LatLng(35.13366, 129.1078),
    "C22 건축관": LatLng(35.13472, 129.1079),
    "C23 호연관": LatLng(35.13529, 129.1077),
    "C24 자연과학 2관": LatLng(35.13573, 129.1077),
    "C25 인문사회경영관": LatLng(35.13426, 129.1076),
    "C28 아름관": LatLng(35.13291, 129.1078),
    "D12 테니스장": LatLng(35.13188, 129.1063),
    "D13 대운동장": LatLng(35.13280, 129.1063),
    "D14 한울관": LatLng(35.13249, 129.1070),
    "D15 창의관": LatLng(35.13281, 129.1069),
    "D21 대학극장": LatLng(35.13239, 129.1050),
    "D22 체육관": LatLng(35.13307, 129.1049),
    "D24 수상레저관": LatLng(35.13268, 129.1049),
    "E11 세종1관": LatLng(35.13123, 129.1050),
    "E12 세종2관": LatLng(35.13120, 129.1043),
    "E13 공학1관": LatLng(35.13179, 129.1037),
    "E14 중앙도서관": LatLng(35.13264, 129.1037),
    "E21 공학2관": LatLng(35.13157, 129.1026),
    "E22 동원장보고관": LatLng(35.13323, 129.1029),
    "E30 행복기숙사": LatLng(35.13137, 129.1063),
    "한솔관": LatLng(35.13165, 129.1047),
    // Add more locations as required
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdates();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final loc.LocationData locationData =
          await _locationController.getLocation();
      setState(() {
        _currentP = LatLng(locationData.latitude!, locationData.longitude!);
      });
    } catch (e) {
      print('Could not get the current location: $e');
    }
  }

  void _startLocationUpdates() {
    _locationController.onLocationChanged
        .listen((loc.LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
      }
    });
  }

  Future<void> _cameraToPosition(LatLng pos, {double zoom = 16}) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(target: pos, zoom: zoom);
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }

  Future<void> _fitPolylineBounds(List<LatLng> polylineCoordinates) async {
    final GoogleMapController controller = await _mapController.future;

    LatLngBounds bounds;
    if (polylineCoordinates.length == 1) {
      bounds = LatLngBounds(
        southwest: polylineCoordinates[0],
        northeast: polylineCoordinates[0],
      );
    } else {
      bounds = _boundsFromLatLngList(polylineCoordinates);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
    await controller.animateCamera(cameraUpdate);
  }

  // Function to add custom marker with an image
  Future<BitmapDescriptor> _createCustomMarkerIcon() async {
    // This assumes you have an image in your assets folder
    return await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)), // Set the size
      'assets/map-marker.png', // Path to your image
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Search'),
      ),
      body: Stack(
        children: [
          if (_currentP == null)
            Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: (GoogleMapController controller) async {
                _mapController.complete(controller);
                String style = await DefaultAssetBundle.of(context).loadString(
                    'assets/map_style.json'); // Load custom map style
                controller.setMapStyle(style);
              },
              initialCameraPosition: CameraPosition(
                target: _currentP ??
                    LatLng(0, 0), // Default to (0,0) until location is fetched
                zoom: 16,
              ),
              onTap: (LatLng tappedLocation) {
                setState(() {
                  _selectedLocation = tappedLocation; // Store tapped location
                });
              },
              markers: _buildMarkers(),
              myLocationEnabled:
                  true, // Use Google Maps default blue circle for current location
              myLocationButtonEnabled: true, // Keep location button enabled
              polylines: Set<Polyline>.of(polylines.values),
            ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                _buildSearchBar(),
                // _buildLocationDropdown(),
                _buildRouteButton(),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                if (_currentP != null) {
                  await _cameraToPosition(
                      _currentP!); // Center on current location
                } else {
                  print('Current location is not available.');
                }
              },
              child: Icon(Icons.my_location), // Location icon
              tooltip: "Show Your Location", // Tooltip on long press
              backgroundColor: const Color.fromARGB(255, 0, 204, 255),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildRouteInfoButton(),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Add a marker for the current position
    if (_currentP != null) {
      markers.add(
        Marker(
          markerId: MarkerId("_currentLocation"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: _currentP!,
          infoWindow: InfoWindow(
            title: "Current Location",
          ),
        ),
      );
    }

    // Add a marker for the selected location from the dropdown
    if (_selectedLocation != null) {
      String buildingName =
          'Selected Location'; // Default name if not found in _locationMap

      // Find the building name using _selectedLocation
      _locationMap.forEach((key, value) {
        if (value == _selectedLocation) {
          buildingName =
              key; // Set buildingName to the key of the matched value
        }
      });

      markers.add(
        Marker(
          markerId: MarkerId("_selectedLocation"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: _selectedLocation!,
          infoWindow: InfoWindow(
            title: buildingName, // Display building name here
          ),
        ),
      );
    }

    return markers;
  }

  void _addPolyline(List<LatLng> polylineCoordinates) {
    if (polylineCoordinates.isNotEmpty) {
      final String polylineIdVal =
          'polyline_id_${DateTime.now().millisecondsSinceEpoch}';
      final PolylineId polylineId = PolylineId(polylineIdVal);

      final Polyline polyline = Polyline(
        polylineId: polylineId,
        color: Colors.blueAccent,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        patterns: [PatternItem.dash(30), PatternItem.gap(10)], // Dashed effect
        points: polylineCoordinates,
      );

      // Clear previous polyline and add the new one
      setState(() {
        polylines.clear(); // Clear all existing polylines
        polylines[polylineId] = polyline; // Add the new polyline
      });
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    double dLon = _degreesToRadians(point2.longitude - point1.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(point1.latitude)) *
            cos(_degreesToRadians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<List<LatLng>> getPolylinePoints(
      LatLng origin, LatLng destination, TravelMode travelMode) async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    try {
      // Fetching polyline coordinates between origin and destination
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: GOOGLE_MAP_API_KEY, // Your Google Maps API Key
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: travelMode,
        ),
      );

      if (result.status == 'OK') {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        // Calculate the total distance and update state
        double totalDistance = 0.0;
        for (int i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += _calculateDistance(
              polylineCoordinates[i], polylineCoordinates[i + 1]);
        }

        setState(() {
          _distance = "${totalDistance.toStringAsFixed(2)} km";
          _duration =
              "${(totalDistance / 5.0 * 60).toStringAsFixed(0)} mins"; // Assuming walking speed 5 km/h
        });
      }
    } catch (e) {
      print("Error getting route: $e");
    }

    return polylineCoordinates;
  }

  Widget _buildRouteButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_currentP != null && _selectedLocation != null) {
          // Ensure that you have a valid destination different from the current location
          if (_currentP != _selectedLocation) {
            List<LatLng> routeCoordinates = await getPolylinePoints(
                _currentP!, _selectedLocation!, TravelMode.transit);

            // Add polyline and update camera
            setState(() {
              _addPolyline(routeCoordinates);
            });

            // Adjust the camera to fit the route bounds
            await _fitPolylineBounds(routeCoordinates);
          } else {
            print(
                "No valid destination selected or it's the same as the current location.");
          }
        }
      },
      child: Text("Route Way"),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController, // Set the controller
              onChanged: (value) {
                setState(() {
                  _filteredLocations = _locationMap.keys
                      .where((location) =>
                          location.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                hintText: "Search here...",
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            if (_filteredLocations.isNotEmpty)
              Container(
                height: 150, // Adjust height based on need
                child: ListView.builder(
                  itemCount: _filteredLocations.length,
                  itemBuilder: (context, index) {
                    String locationName = _filteredLocations[index];
                    return ListTile(
                      title: Text(locationName),
                      onTap: () {
                        LatLng selectedLatLng = _locationMap[locationName]!;
                        setState(() {
                          _selectedLocation = selectedLatLng;
                          _searchController.text =
                              locationName; // Update search field
                          _filteredLocations
                              .clear(); // Hide the suggestion list
                        });
                        _cameraToPosition(selectedLatLng);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget _buildLocationDropdown() {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 16.0),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(8.0),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black26,
  //           blurRadius: 4.0,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: DropdownButton<LatLng>(
  //       isExpanded: true,
  //       hint: Text('Select a location'),
  //       underline: SizedBox(),
  //       items: _locationMap.entries.map((entry) {
  //         return DropdownMenuItem<LatLng>(
  //           value: entry.value,
  //           child: Text(entry.key),
  //         );
  //       }).toList(),
  //       onChanged: (LatLng? selectedLocation) async {
  //         if (selectedLocation != null) {
  //           // Store the selected location
  //           setState(() {
  //             _selectedLocation = selectedLocation;
  //           });

  //           // Optionally, you can move the camera to the selected location
  //           await _cameraToPosition(selectedLocation);

  //           // Add polyline to the selected location if needed
  //           List<LatLng> routeCoordinates = await getPolylinePoints(
  //               _currentP!, selectedLocation, TravelMode.walking);

  //           // Call _addPolyline to clear old polyline and add new one
  //           _addPolyline(routeCoordinates);
  //         }
  //       },
  //     ),
  //   );
  // }

  Widget _buildRouteInfoButton() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Route Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("Distance: ${_distance ?? 'Unknown'}"),
                  Text("Estimated Time: ${_duration ?? 'Unknown'}"),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Close"),
                  )
                ],
              ),
            );
          },
        );
      },
      child: Icon(Icons.info),
      backgroundColor: Colors.blueAccent,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OpenStreetMapPicker extends StatefulWidget {
  final LatLng? initialLocation;
  const OpenStreetMapPicker({super.key, this.initialLocation});

  @override
  State<OpenStreetMapPicker> createState() => _OpenStreetMapPickerState();
}

class _OpenStreetMapPickerState extends State<OpenStreetMapPicker> {
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();
    // Use provided initial location or default to Pune
    selectedLocation = widget.initialLocation ?? LatLng(18.5204, 73.8567);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Shop Location")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: selectedLocation,
              zoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.eastnshop.vendor',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 80,
                    height: 80,
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              child: const Text("Confirm Location"),
              onPressed: () {
                Navigator.pop(context, selectedLocation);
              },
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "© OpenStreetMap contributors © CARTO",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

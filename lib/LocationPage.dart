import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String locationText = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _checkLocationServiceEnabled();
  }

  void _checkLocationServiceEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationText = 'Location services are disabled.';
      });
      return;
    }
    _requestLocationPermission();
  }

  void _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        locationText = 'Location permission is denied.';
      });
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationText =
            'Location permission is permanently denied, we cannot request permissions.';
      });
      return;
    }
    _getLocation();
  }

  void _getLocation() async {
    try {
      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Access latitude and longitude
      double latitude = position.latitude;
      double longitude = position.longitude;

      // Set the location text
      setState(() {
        locationText = 'Latitude: $latitude, Longitude: $longitude';
      });
    } catch (e) {
      setState(() {
        locationText = 'Error fetching location: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location'),
      ),
      body: Center(
        child: Text(locationText),
      ),
    );
  }
}

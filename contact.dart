import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>> nearbyContacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    requestPermissionsAndFetchContacts();
  }

  Future<void> requestPermissionsAndFetchContacts() async {
    final permissionStatus = await [
      Permission.contacts,
      Permission.location,
    ].request();

    if (permissionStatus[Permission.contacts] == PermissionStatus.granted &&
        permissionStatus[Permission.location] == PermissionStatus.granted) {
      fetchAndFilterContacts();
    } else {
      _showSnackBar("Permissions not granted! Enable contacts & location.");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAndFilterContacts() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch user's current location
      final userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Fetch phone contacts
      final phoneContacts = await FlutterContacts.getContacts(withProperties: true);
      List<Map<String, dynamic>> validContacts = [];

      for (var contact in phoneContacts) {
        if (contact.phones.isEmpty) continue; // Skip if no phone number

        // Format phone number (remove spaces, dashes, etc.)
        String formattedPhone = contact.phones.first.number.replaceAll(RegExp(r'[^\d]'), '');

        // Query Firestore for the phone number
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: formattedPhone)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          if (data.containsKey('latitude') && data.containsKey('longitude')) {
            final double contactLat = data['latitude'];
            final double contactLng = data['longitude'];

            // Calculate distance between user and contact
            final double distance = Geolocator.distanceBetween(
                userPosition.latitude, userPosition.longitude, contactLat, contactLng);

            if (distance <= 2000) { // Only include contacts within 2 km
              validContacts.add({
                'contact': contact,
                'distance': distance
              });
            }
          }
        }
      }

      // Sort contacts by nearest distance
      validContacts.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        nearbyContacts = validContacts;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching contacts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby App Users")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : nearbyContacts.isEmpty
              ? const Center(child: Text("No contacts found within 2km"))
              : ListView.builder(
                  itemCount: nearbyContacts.length,
                  itemBuilder: (context, index) {
                    Contact contact = nearbyContacts[index]['contact'];
                    double distance = nearbyContacts[index]['distance'];

                    return ListTile(
                      title: Text(contact.displayName),
                      subtitle: Text(
                        '${contact.phones.isNotEmpty ? contact.phones.first.number : 'No number'}\n'
                        'Distance: ${distance.toStringAsFixed(2)} km',
                      ),
                      trailing: Icon(Icons.location_on, color: Colors.red),
                    );
                  },
                ),
    );
  }
}

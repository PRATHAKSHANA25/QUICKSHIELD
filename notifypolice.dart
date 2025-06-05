import 'package:flutter/material.dart';

class NotifyPolice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notify Police")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showConfirmDialog(context),
          child: const Text("Notify Police"),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Notify Police?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Add police notification logic here
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

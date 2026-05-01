import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Places, Users, Reviews
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Admin Panel",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.place), text: "Places"),
              Tab(icon: Icon(Icons.people), text: "Users"),
              Tab(icon: Icon(Icons.rate_review), text: "Reviews"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [ManagePlacesTab(), ManageUsersTab(), ManageReviewsTab()],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            // Yahan se AddPlaceScreen par jayenge (Create operation)
            _showAddPlaceDialog(context);
          },
        ),
      ),
    );
  }

  // --- Quick Add Place Dialog (Conceptual) ---
  void _showAddPlaceDialog(BuildContext context) {
    // Aap yahan ek naya form screen khol sakte hain jo
    // Cloudinary upload aur Firestore set use kare.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Navigate to Add Place Form")));
  }
}

// --- Tab 1: Manage Places ---
class ManagePlacesTab extends StatelessWidget {
  const ManagePlacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return ListTile(
              leading: Image.network(
                data['image'] ?? '',
                width: 50,
                fit: BoxFit.cover,
              ),
              title: Text(data['name'] ?? 'No Name'),
              subtitle: Text(data['category'] ?? 'General'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => doc.reference.delete(),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Tab 2: Manage Users ---
class ManageUsersTab extends StatelessWidget {
  const ManageUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(child: Text(data['username']?[0] ?? 'U')),
              title: Text(data['username'] ?? 'Anonymous'),
              subtitle: Text(data['email'] ?? ''),
              trailing: const Icon(
                Icons.admin_panel_settings,
                color: Colors.blue,
              ),
            );
          },
        );
      },
    );
  }
}

// --- Tab 3: Manage Reviews ---
class ManageReviewsTab extends StatelessWidget {
  const ManageReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('reviews').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['comment'] ?? ''),
              subtitle: Text("Rating: ${data['stars']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => doc.reference.delete(),
              ),
            );
          },
        );
      },
    );
  }
}

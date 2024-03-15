// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_detail_page.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({Key? key}) : super(key: key);

  @override
  _ActivitiesPageState createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> with TickerProviderStateMixin {
  TabController? _tabController;
  List<String> categories = ['Tous'];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  void fetchCategories() async {
    final QuerySnapshot categorySnapshot = await FirebaseFirestore.instance.collection('activities').get();
    final allActivities = categorySnapshot.docs.map((doc) => Activity.fromSnapshot(doc)).toList();
    final newCategories = ['Tous'];
    for (var activity in allActivities) {
      if (!newCategories.contains(activity.category)) {
        newCategories.add(activity.category);
      }
    }

    if (mounted) {
      setState(() {
        categories = newCategories;
        _tabController = TabController(length: categories.length, vsync: this);
      });
    }
  }

 @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Liste des Activités',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Arial',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: UnderlineTabIndicator(borderSide: BorderSide(color: Colors.orange, width: 4.0)),
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.white,
              labelStyle: TextStyle(fontSize: 17),
              tabs: categories.map((String category) => Tab(text: category)).toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: TabBarView(
                controller: _tabController,
                children: categories.map((String category) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: category == 'Tous'
                        ? FirebaseFirestore.instance.collection('activities').snapshots()
                        : FirebaseFirestore.instance.collection('activities').where('category', isEqualTo: category).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Erreur de chargement des activités'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var activities = snapshot.data!.docs.map((doc) => Activity.fromSnapshot(doc)).toList();
                      activities.sort((a, b) => a.title.compareTo(b.title));

                      return ListView.builder(
                        padding: EdgeInsets.only(top: 8.0),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          return ActivityWidget(activity: activities[index]);
                        },
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}

class ActivityWidget extends StatelessWidget {
  final Activity activity;

  const ActivityWidget({Key? key, required this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      constraints: BoxConstraints(maxHeight: 100),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailPage(activity: activity),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
              ),
              child: Image.network(
                activity.imageUrl,
                width: MediaQuery.of(context).size.width / 3,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      '${activity.location}\n${activity.price} euros',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Activity {
  final String imageUrl;
  final String title;
  final String location;
  final double price;
  final String category;
  final int minParticipants;
  final String description;

  Activity({
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    required this.category,
    required this.minParticipants,
    required this.description,
  });

  factory Activity.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Activity(
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      price: data['price'].toDouble(),
      category: data['category'] ?? '',
      minParticipants: data['minParticipants'],
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'location': location,
      'price': price,
      'category': category,
      'minParticipants': minParticipants,
      'description': description,
    };
  }
}

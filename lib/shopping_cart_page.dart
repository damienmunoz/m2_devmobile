// ignore_for_file: prefer_const_constructors, avoid_print, library_private_types_in_public_api, prefer_interpolation_to_compose_strings
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'activities_page.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({Key? key}) : super(key: key);

  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Activity>>(
      future: ShoppingCart.getUserCart(FirebaseAuth.instance.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<Activity> activities = snapshot.data!;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text('Panier', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Arial')),
              centerTitle: true,
              backgroundColor: Colors.orange,
            ),
            body: Column(
              children: [
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 8.0),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
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
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8.0),
                                bottomLeft: Radius.circular(8.0),
                              ),
                              child: Image.network(
                                activities[index].imageUrl,
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
                                      activities[index].title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text('${activities[index].location}\n${activities[index].price} euros', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.symmetric(vertical: 25.0, horizontal: 25.0),
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                  await ShoppingCart().removeFromCart(activities[index], FirebaseAuth.instance.currentUser!.uid);
                                  final updatedActivities = await ShoppingCart.getUserCart(FirebaseAuth.instance.currentUser!.uid);
                                  setState(() {
                                    activities = updatedActivities;
                                  }
                                );
                              },
                              alignment: Alignment.centerRight,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                FutureBuilder<double>(
                  future: ShoppingCart.calculateTotal(FirebaseAuth.instance.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        padding: EdgeInsets.only(bottom: 80, top:30, left:13, right:13),
                        child: Column(
                          
                          children: [
                            Container(
                              height: 2.0,
                              width: double.infinity,
                              color: Colors.orange,
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Total : ', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                                Text('${snapshot.data} euros', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}



class ShoppingCart {
  static final ShoppingCart _instance = ShoppingCart._internal();
  factory ShoppingCart() => _instance;
  
  ShoppingCart._internal();

  Future<void> addToCart(Activity activity, String userId) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      final cartCollection = userDoc.collection('cart');
      
      await cartCollection.add(activity.toMap());
      Fluttertoast.showToast(
        msg: "Ajout " + activity.title + " au panier",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        fontSize: 16.0,
        webPosition: "center",
        webBgColor:"#006400",
      );
    } catch (e) {
      print('Error adding activity to cart: $e');
    }
  }

Future<void> removeFromCart(Activity activity, String userId) async {
  try {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final cartCollection = userDoc.collection('cart');
    final querySnapshot = await cartCollection.where('title', isEqualTo: activity.title).get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await cartCollection.doc(docId).delete();
      Fluttertoast.showToast(
        msg: "Suppression " + activity.title + " du panier",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        fontSize: 16.0,
        webPosition: "center",
        webBgColor:"#006400",
      );
    }
  } catch (e) {
    print('Error removing activity from cart: $e');
  }
}

static Future<List<Activity>> getUserCart(String userId) async {
  try {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final cartCollection = userDoc.collection('cart');
    final querySnapshot = await cartCollection.get();
    
    List<Activity> userCart = [];
    for (var doc in querySnapshot.docs) {
      if (doc.data().containsKey('title') && doc.data()['title'].toString().isNotEmpty) {
        Activity activity = Activity.fromSnapshot(doc);
        userCart.add(activity);
      } else {
        await cartCollection.doc(doc.id).delete();
        print('Deleted empty activity with id: ${doc.id}');
      }
    }

    userCart.sort((a, b) => a.title.compareTo(b.title));
    return userCart;
  } catch (e) {
    print('Error getting user cart: $e');
    return [];
  }
}

static Future<double> calculateTotal(String userId) async {
  try {
    final userCart = await getUserCart(userId);
    double total = 0;
    for (var activity in userCart) {
      total += activity.price;
    }
    String totalStr = total.toStringAsFixed(2);
    return double.parse(totalStr);
  } catch (e) {
    print('Error calculating total: $e');
    return 0;
  }
}
}

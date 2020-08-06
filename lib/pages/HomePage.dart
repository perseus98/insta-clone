import 'dart:io';

import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/CreateAccountPage.dart';
import 'package:buddiesgram/pages/NotificationsPage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/pages/SearchPage.dart';
import 'package:buddiesgram/pages/TimeLinePage.dart';
import 'package:buddiesgram/pages/UploadPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final userReference = Firestore.instance.collection("users");
final postReference = Firestore.instance.collection("posts");
final StorageReference storageReference =
    FirebaseStorage.instance.ref().child("Posted Pictures");
final activityFeedReference = Firestore.instance.collection("feed");
final commentsReference = Firestore.instance.collection("comments");
final followingReference = Firestore.instance.collection("following");
final followersReference = Firestore.instance.collection("followers");
final timelineReference = Firestore.instance.collection("timeline");

final DateTime timeStamp = DateTime.now();
User currentUser;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSignedIn = false;
  PageController pageController;
  int getPageIndex = 0;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    if (isSignedIn) {
      return buildHomeScreen();
    } else {
      return buildSignInScreen();
    }
  }

  void initState() {
    super.initState();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((gSigninAccount) {
      controlSignIn(gSigninAccount);
    }, onError: (gError) {
      print("Auth Err" + gError);
    });
    googleSignIn.signInSilently(suppressErrors: false).then((gSigninAccount) {
      controlSignIn(gSigninAccount);
    }).catchError((gError) {
      print("Auth Err" + gError);
    });
  }

  controlSignIn(GoogleSignInAccount signInAccount) async {
    if (signInAccount != null) {
      await saveUserInfoToFirebase();
      setState(() {
        isSignedIn = true;
      });
//      configureRealTimePushNotification();
    } else {
      setState(() {
        isSignedIn = false;
      });
    }
  }

  configureRealTimePushNotification() {
    final GoogleSignInAccount gUser = googleSignIn.currentUser;
    if (Platform.isIOS) {
      getIOSPermissions();
    }

    _firebaseMessaging.getToken().then((value) {
      userReference.document(gUser.id).updateData(
          {"androidNotificationToken": value});
    });

    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> msg) async {
          final String recipientId = msg["data"]["recipient"];
          final String body = msg["notification"]["body"];

          if (recipientId == gUser.id) {
            SnackBar snackBar = SnackBar(
              backgroundColor: Colors.grey,
              content: Text(body, style: TextStyle(color: Colors.black),
                overflow: TextOverflow.ellipsis,),
            );
            _scaffoldKey.currentState.showSnackBar(snackBar);
          }
        }
    );
  }

  getIOSPermissions() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, sound: true, badge: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((event) {
      print("Settings Registered : $event");
    });
  }


  saveUserInfoToFirebase() async {
    final GoogleSignInAccount gCurrentAccount = googleSignIn.currentUser;
    DocumentSnapshot documentSnapshot =
    await userReference.document(gCurrentAccount.id).get();

    if (!documentSnapshot.exists) {
      final username = await Navigator.push(context,
          MaterialPageRoute(builder: (context) => CreateAccountPage()));
      userReference.document(gCurrentAccount.id).setData({
        "id": gCurrentAccount.id,
        "profileName": gCurrentAccount.displayName,
        "username": username,
        "url": gCurrentAccount.photoUrl,
        "email": gCurrentAccount.email,
        "bio": "",
        "timestamp": timeStamp,
      });
      await followersReference.document(gCurrentAccount.id).collection(
          "userFollowers").document(gCurrentAccount.id).setData({});
      documentSnapshot = await userReference.document(gCurrentAccount.id).get();
    }
    currentUser = User.fromDocument(documentSnapshot);
  }

  loginUser() {
    googleSignIn.signIn();
  }

  logoutUser() {
    googleSignIn.signOut();
  }

  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // ignore: non_constant_identifier_names
  WhenPageChange(int index) {
    setState(() {
      this.getPageIndex = index;
    });
  }

  onTapChangePage(int index) {
    pageController.animateToPage(index,
        duration: Duration(milliseconds: 400), curve: Curves.bounceInOut);
  }

  Scaffold buildHomeScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(gCurrentUser: currentUser),
          SearchPage(),
          UploadPage(
            gCurrentUser: currentUser,
          ),
          NotificationsPage(),
          ProfilePage(
            userProfileId: currentUser.id,
          ),
        ],
        controller: pageController,
        onPageChanged: WhenPageChange,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: Theme.of(context).accentColor,
        activeColor: Colors.white,
        inactiveColor: Colors.blueGrey,
        currentIndex: getPageIndex,
        onTap: onTapChangePage,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.photo_camera,
                size: 37.0,
              )),
          BottomNavigationBarItem(icon: Icon(Icons.favorite)),
          BottomNavigationBarItem(icon: Icon(Icons.person)),
        ],
      ),
    );
//    return RaisedButton.icon(onPressed: logoutUser, icon: Icon(Icons.close), label: Text("Sign Out"));
  }

  Scaffold buildSignInScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Theme.of(context).accentColor,
                  Theme.of(context).primaryColor
                ])),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Social_Clone",
              style: TextStyle(
                  fontSize: 92.0, color: Colors.white, fontFamily: "Signatra"),
            ),
            GestureDetector(
              onTap: loginUser(),
              child: Container(
                width: 270.0,
                height: 65.0,
                decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/google_signin_button.png"),
                      fit: BoxFit.cover,
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }
}

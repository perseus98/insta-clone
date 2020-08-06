import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/PostWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TimeLinePage extends StatefulWidget {
  final User gCurrentUser;

  TimeLinePage({this.gCurrentUser});

  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage> {
  List<Post> posts;
  List<String> followingsList = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    retrieveTimeline();
    retrieveFollowing();
  }

  retrieveTimeline() async {
    QuerySnapshot querySnapshot = await timelineReference
        .document(widget.gCurrentUser.id)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();
    List<Post> allPosts =
        querySnapshot.documents.map((e) => Post.fromDocument(e)).toList();
    setState(() {
      this.posts = allPosts;
    });
  }

  retrieveFollowing() async {
    QuerySnapshot querySnapshot = await followingReference
        .document(widget.gCurrentUser.id)
        .collection("userFollowing")
        .getDocuments();
    setState(() {
      followingsList =
          querySnapshot.documents.map((e) => e.documentID).toList();
    });
  }

  @override
  Widget build(context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
        child: createUserTimeline(),
        onRefresh: () => retrieveTimeline(),
      ),
    );
  }

  createUserTimeline() {
    if (posts == null) {
      return circularProgress();
    } else {
      return ListView(
        children: posts,
      );
    }
  }
}

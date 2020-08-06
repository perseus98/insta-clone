import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tAgo;

import 'ProfilePage.dart';

String notificationItemText;
Widget mediapreview;

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: "Notification"),
      body: Container(
        child: FutureBuilder(
          future: retrieveNotification(),
          builder: (context, dataSnapshot) {
            if (!dataSnapshot.hasData) {
              return circularProgress();
            }
            return ListView(
              children: dataSnapshot.data,
            );
          },
        ),
      ),
    );
  }

  retrieveNotification() async {
    QuerySnapshot querySnapshot = await activityFeedReference
        .document(currentUser.id)
        .collection("feedItems")
        .orderBy("timestamp", descending: true)
        .limit(60)
        .getDocuments();

    List<NotificationsItem> notificationItems = [];
    querySnapshot.documents.forEach((document) {
      notificationItems.add(NotificationsItem.fromDocument(document));
    });
    return notificationItems;
  }
}

class NotificationsItem extends StatelessWidget {
  final String username;
  final String type;
  final String commentDate;
  final String postId;
  final String userId;
  final String userProfileImg;
  final String url;
  final Timestamp timestamp;

  NotificationsItem(
      {this.username, this.type, this.commentDate, this.timestamp, this.url, this.postId, this.userId, this.userProfileImg});

  factory NotificationsItem.fromDocument(DocumentSnapshot documentSnapshot){
    return NotificationsItem(
      username: documentSnapshot["username"],
      type: documentSnapshot["type"],
      commentDate: documentSnapshot["commentDate"],
      postId: documentSnapshot["postId"],
      userId: documentSnapshot["userId"],
      userProfileImg: documentSnapshot["userProfileImg"],
      url: documentSnapshot["url"],
      timestamp: documentSnapshot["timestamp"],
    );
  }

  @override
  Widget build(context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => displayUserProfile(context, userProfileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 14.0, color: Colors.black),
                children: [
                  TextSpan(text: username,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "$notificationItemText"),
                ],
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            tAgo.format(timestamp.toDate()), overflow: TextOverflow.ellipsis,),
          trailing: mediapreview,
        ),
      ),
    );
  }

  configureMediaPreview(BuildContext context) {
    if (type == "comment" || type == "like") {
      mediapreview = GestureDetector(
        onTap: () => displayOwnProfile(context, userProfileId: currentUser.id),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.cover, image: CachedNetworkImageProvider(url)),
              ),
            ),
          ),
        ),
      );
    } else {
      mediapreview = Text("");
    }
    if (type == "like") {
      notificationItemText = " liked your post.";
    } else if (type == "comment") {
      notificationItemText = " replied: $commentDate";
    } else if (type == "follow") {
      notificationItemText = " started following you";
    } else {
      notificationItemText = " Error, Unknown type = $type";
    }
  }

  displayOwnProfile(BuildContext context, {String userProfileId}) {
    Navigator.push(context, MaterialPageRoute(
        builder: (context) => ProfilePage(userProfileId: currentUser.id,)));
  }

  displayUserProfile(BuildContext context, {String userProfileId}) {
    Navigator.push(context, MaterialPageRoute(
        builder: (context) => ProfilePage(userProfileId: userProfileId)));
  }
}

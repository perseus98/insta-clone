import 'dart:io';
import 'dart:ui';

import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as ImD;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class UploadPage extends StatefulWidget {
  final User gCurrentUser;

  UploadPage({this.gCurrentUser});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with AutomaticKeepAliveClientMixin<UploadPage> {

  bool get wantKeepAlive => true;
  bool uploading = false;
  String postId = Uuid().v4();
  File file;
  TextEditingController descriptionTextEditingController = TextEditingController();
  TextEditingController locationTextEditingController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return file == null ? displayUploadScreen() : displayUploadFormScreen();
  }

  displayUploadFormScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black26,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white,),
            onPressed: clearPostInfo),
        title: Text("New Post", style: TextStyle(
            fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),),
        actions: <Widget>[
          FlatButton(
            onPressed: uploading ? null : () => controlUploadAndSave(),
            child: Text("Share", style: TextStyle(
                color: Colors.lightGreenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16.0),),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          uploading ? linearProgress() : Text(""),
          Container(
            height: 230.0,
            width: MediaQuery
                .of(context)
                .size
                .width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(image: DecorationImage(
                    image: FileImage(file), fit: BoxFit.fill,)),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 12.0),),
          ListTile(
            leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(
                widget.gCurrentUser.url),),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: descriptionTextEditingController,
                decoration: InputDecoration(
                  hintText: "Say something about your image...",
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.person_pin, color: Colors.white, size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: locationTextEditingController,
                decoration: InputDecoration(
                  hintText: "Write about your location...",
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            height: 220.0,
            width: 110.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
                onPressed: getUserCurrentLocation,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35.0)),
                icon: Icon(Icons.location_on, color: Colors.white,),
                label: Text("Get my current location",
                  style: TextStyle(color: Colors.white),)
            ),
          )
        ],
      ),
    );
  }

  controlUploadAndSave() async {
    setState(() {
      uploading = true;
    });
    await compressingPhoto();
    String downloadUrl = await uploadFile(file);
    savePostInfoToFireStore(url: downloadUrl,
        location: locationTextEditingController.text,
        description: descriptionTextEditingController.text);

    locationTextEditingController.clear();
    descriptionTextEditingController.clear();

    setState(() {
      file = null;
      uploading = false;
      postId = Uuid().v4();
    });
  }

  savePostInfoToFireStore({String url, String location, String description}) {
    postReference.document(widget.gCurrentUser.id)
        .collection("usersPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.gCurrentUser.id,
      "timestamp": timeStamp,
      "likes": {},
      "username": widget.gCurrentUser.username,
      "description": description,
      "location": location,
      "url": url,
    });
  }

  Future<String> uploadFile(mImageFile) async {
    StorageUploadTask storageUploadTask = storageReference.child(
        "post_$postId.jpg").putFile(mImageFile);
    StorageTaskSnapshot storageTaskSnapshot = await storageUploadTask
        .onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  compressingPhoto() async {
    final tDirectory = await getTemporaryDirectory();
    final dPath = tDirectory.path;
    ImD.Image mImageFile = ImD.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$dPath/img_$postId.jpg')
      ..writeAsBytesSync(ImD.encodeJpg(mImageFile, quality: 90));
    setState(() {
      file = compressedImageFile;
    });
  }

  getUserCurrentLocation() async {
    Position position = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(
        position.latitude, position.longitude);
    Placemark mPlaceMark = placemarks[0];
    String completeAddressInfo = '${mPlaceMark.subThoroughfare}${mPlaceMark
        .thoroughfare},'
        '${mPlaceMark.subLocality}${mPlaceMark.locality},'
        '${mPlaceMark.subAdministrativeArea}${mPlaceMark.administrativeArea},'
        '${mPlaceMark.postalCode}${mPlaceMark.country}';
    String specificAddress = '${mPlaceMark.locality},${mPlaceMark.country}';
    locationTextEditingController.text = specificAddress;
  }

  clearPostInfo() {
    locationTextEditingController.clear();
    descriptionTextEditingController.clear();
    setState(() {
      file = null;
    });
  }

  displayUploadScreen() {
    return Container(
      color: Theme
          .of(context)
          .accentColor
          .withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.add_photo_alternate, color: Colors.grey, size: 200.0,),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9.0),),
                child: Text("Upload Image",
                  style: TextStyle(color: Colors.white, fontSize: 20.0),),
                color: Colors.green,
                onPressed: () => takeImage(context)
            ),
          )
        ],
      ),
    );
  }

  takeImage(mContext) {
    return showDialog<void>(
      context: mContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("New Post", style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
          children: <Widget>[
            SimpleDialogOption(
              child: Text("Capture Image with Camera",
                style: TextStyle(color: Colors.white),),
              onPressed: captureImageWithCamera,
            ),
            SimpleDialogOption(
              child: Text(
                "Select From Gallery", style: TextStyle(color: Colors.white),),
              onPressed: pickFromGallery,
            ),
            SimpleDialogOption(
              child: Text("Cancel", style: TextStyle(color: Colors.white),),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  captureImageWithCamera() async {
    Navigator.pop(context);
    File imageFile = (await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 680,
      maxWidth: 970,
    ));
    setState(() {
      this.file = imageFile;
    });
  }

  pickFromGallery() async {
    Navigator.pop(context);
    File imageFile = (await ImagePicker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 680,
      maxWidth: 970,
    ));
    setState(() {
      this.file = imageFile;
    });
  }

}

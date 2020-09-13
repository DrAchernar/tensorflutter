import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math' as math;
import 'dart:async';

import 'tf/camera.dart';
import 'tf/detector.dart';

enum TtsState { playing, stopped }

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage(this.cameras);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  String _model = "";
  Timer timer;
  String target = '';

  final List<String> images = [
    "https://freedesignfile.com/upload/2018/08/The-latest-slim-laptop-Stock-Photo-280x235.jpg",
    "https://freedesignfile.com/upload/2018/04/Umbrella-in-the-rain-Stock-Photo-01-280x235.jpg",
    "https://freedesignfile.com/upload/2018/07/Man-sitting-resting-on-bicycle-Stock-Photo-280x235.jpg",
    "https://freedesignfile.com/upload/2018/11/Stock-Photo-Two-hummingbirds-standing-on-branch-280x235.jpg",
    "https://freedesignfile.com/upload/2019/05/Tabby-cat-with-red-bell-Stock-Photo-280x235.jpg",
    "https://freedesignfile.com/upload/2019/04/Ford-Mustang-blue-cars-Stock-Photo-280x235.jpg",
    "https://freedesignfile.com/upload/2018/05/Young-beauty-girl-wearing-white-blouse-Stock-Photo-08-280x235.jpg",
    "https://freedesignfile.com/upload/2016/12/Smart-phone-data-cable-HD-picture-280x235.jpg",
  ], names = [
    "laptop",
    "umbrella",
    "bicycle",
    "bird",
    "cat",
    "car",
    "person",
    "phone"
  ];


  FlutterTts flutterTts = FlutterTts();
  TtsState ttsState = TtsState.stopped;

  @override
  void initState() {
    super.initState();
    timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      _speak();
    });
  }

  Future _speak() async {
    if (_recognitions != null && ttsState == TtsState.stopped) {
      var rec = _recognitions.map((re) {
        return re["detectedClass"];
      }).toList();
      for (var _target in rec) {
        if (_target.toString() == target) {
          var result = await flutterTts.speak('Warning! $target detected.');
          if (result == 1) setState(() => ttsState = TtsState.playing);
          ttsDelay().then((_) {
            setState(() {
              ttsState = TtsState.stopped;
            });
          });
        }
      }
    }
  }

  Future ttsDelay() async {
    await Future.delayed(Duration(seconds: 6));
  }

  loadModel() async {
    setState(() {
      _model = "SSD MobileNet";
    });
    String res;
    res = await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt");
    print(res);
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.find_replace),
              onPressed: () {
                setState(() {
                  _model = "";
                });
                target = "";
              })
        ],
        title: Text('tflite example'),
        automaticallyImplyLeading: false,
      ),
      body: _model == ""
          ? new StaggeredGridView.countBuilder(
        crossAxisCount: 4,
        itemCount: 8,
        itemBuilder: (BuildContext context, int index) => new Container(
            child: new GestureDetector(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(images[index]),
                    fit: BoxFit.cover,
                  ),
              ),
                child: Center(
                  child: Text(
                    '${names[index]}',
                    style: TextStyle(
                      backgroundColor: Colors.black54,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ),
              onTap: () {
                target = names[index];
                loadModel();
              },
              ),
            ),
        staggeredTileBuilder: (int index) =>
        new StaggeredTile.count(2, index.isEven ? 2 : 1),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      )
          : Stack(
              children: [
                Camera(
                  widget.cameras,
                  _model,
                  setRecognitions,
                ),
                Detector(
                  _recognitions == null ? [] : _recognitions,
                  math.max(_imageHeight, _imageWidth),
                  math.min(_imageHeight, _imageWidth),
                  screen.height,
                  screen.width,
                  _model,
                  target,
                ),
              ],
            ),
    );
  }
}

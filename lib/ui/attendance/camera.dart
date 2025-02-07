import 'dart:io';
import 'dart:math';

import 'package:attendance_edit/ui/attendance/attendance_screen.dart';
import 'package:attendance_edit/utils/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  FaceDetector faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
          enableTracking: true,
          enableLandmarks: true));
  List<CameraDescription>? cameras;
  CameraController? controller;
  bool isBusy = false;
  XFile? image;

  @override
  void initState() {
    loadCamera();
    super.initState();
  }

// if 1 = front camera, if 0 = back camera
  loadCamera() async {
    cameras = await availableCameras();
    if (cameras != null) {
      controller = CameraController(cameras![1], ResolutionPreset.max);
      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(
          children: [
            Icon(Icons.camera_enhance_outlined, color: Colors.white),
            SizedBox(width: 10),
            Text('No camera found', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        shape: StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text(
          "Capture a selfie image",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            width: size.width,
            height: size.height,
            child: controller == null
                ? const Center(
                    child: Text("Ups, Camera error!"),
                  )
                : !controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : Transform.rotate(
                        angle: _getRotationAngle(
                            controller!.value.deviceOrientation),
                        child: CameraPreview(controller!),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child:
                Lottie.asset("assets/raw/face_id_ring.json", fit: BoxFit.cover),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: size.width,
                height: 200,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Make sure your face is clearly visible",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: ClipOval(
                        child: Material(
                          color: Colors.blueAccent, //button color
                          child: _buildCameraCapture(),
                        ),
                      ),
                    )
                  ],
                ),
              ))
        ],
      ),
    );
  }

  showLoaderDialog(BuildContext context) {
      AlertDialog alert = AlertDialog(
          content: Row(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: const Text("Checking the Data..."),
          )
        ],
      ));
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return alert;
          });
    }

  Widget _buildCameraCapture() {
    return InkWell(
      splashColor: Colors.blue, // splash color
      onTap: () async {
        final hasPermission = await handleLocationPermission();
        try {
          if (controller != null) {
            if (controller!.value.isInitialized) {
              controller!.setFlashMode(FlashMode.off);
              image = await controller!.takePicture();
              setState(() {
                if (hasPermission) {
                  showLoaderDialog(context);
                  final inputImage = InputImage.fromFilePath(image!.path);
                  Platform.isAndroid
                      ? processImage(inputImage)
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  AttendScreen(image: image)));
                } else {
                  _showSnackBar(
                      icon: Icons.location_on_outlined,
                      message: "Please allow location permission first!",
                      color: Colors.blueGrey);
                }
              });
            }
          }
        } catch (e) {
          // ignore: use_build_context_synchronously\
          _showSnackBar(
              icon: Icons.face_retouching_off_outlined,
              message: "Ups, something went wrong! Please try again",
              color: Colors.blueGrey);
        }
      },
      child: const SizedBox(
        width: 60,
        height: 60,
        child: Icon(
          Icons.camera_alt,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showSnackBar({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Text(message)
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // ignore: use_build_context_synchronously
      _showSnackBar(
          icon: Icons.location_off,
          message: "Please enable location service",
          color: Colors.blueGrey);
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // ignore: use_build_context_synchronously
        _showSnackBar(
            icon: Icons.location_off,
            message:
                "Location permissions are denied. Please enable location service",
            color: Colors.blueGrey);
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // ignore: use_build_context_synchronously
      _showSnackBar(
          icon: Icons.location_off,
          message:
              "Location permissions are denied forever. We cannot access location service",
          color: Colors.blueGrey);
      return false;
    }
    return true;
  }

  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage);
    isBusy = false;

    if (mounted) {
      setState(() {
        Navigator.of(context).pop(true);
        if (faces.isNotEmpty) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AttendScreen(
                        image: image,
                      )));
        } else {
          _showSnackBar(
              icon: Icons.face_retouching_off_outlined,
              message: "Ups, make sure that you're face is clearly visible!",
              color: Colors.blueGrey);
        }
      });
    }
  }

  double _getRotationAngle(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portraitUp:
        return 0;
      case DeviceOrientation.landscapeLeft:
        return 90 * (pi / 180); // 90 derajat dalam radian
      case DeviceOrientation.portraitDown:
        return 180 * (pi / 180); // 180 derajat dalam radian
      case DeviceOrientation.landscapeRight:
        return 270 * (pi / 180);
    }
  }
}

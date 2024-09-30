import 'dart:convert'; // Ensure to import for JSON decoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Camera Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CameraDescription>? cameras;
  CameraController? controller;
  int selectedCameraIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String weatherInfo = 'Loading weather...';
  String? imagePath; // Variable to store the path of the captured image

  String selectedFilter = 'None';
  double filterSliderValue = 0;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    initCamera();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    const String apiKey =
        'a0d63355b66540d793c104957242409';
    const String city = 'Bangkok';
    const String url =
        'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city&aqi=no';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final weatherData = json.decode(response.body);
      final description =
          weatherData['current']['condition']['text'];
      final temperature = weatherData['current']['temp_c'];
      setState(() {
        weatherInfo = 'Weather: $description, Temperature: $temperature°C';
      });
    } else {
      setState(() {
        weatherInfo = 'Unable to fetch weather data';
      });
    }
  }

  Future<void> requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
    ].request();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller =
          CameraController(cameras![selectedCameraIndex], ResolutionPreset.max);
      try {
        await controller!.initialize();
        setState(() {});
      } catch (e) {
        print('Error initializing camera: $e');
      }
    } else {
      print('No camera available');
      setState(() {
        cameras = [];
      });
    }
  }

  Future<void> switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    await controller?.dispose();
    await initCamera();
  }

  Future<void> _takePicture() async {
    if (controller != null && controller!.value.isInitialized) {
      try {
        XFile image = await controller!.takePicture();
        await _audioPlayer.play(
            AssetSource('camera-shutter-199580.mp3'));
        await GallerySaver.saveImage(image.path, toDcim: true);
        setState(() {
          imagePath = image.path; // Save the image path for later use
        });
      } catch (e) {
        print('Error taking picture: $e');
      }
    }
  }

  // Function to download the captured image
  Future<void> downloadImage() async {
    if (imagePath != null) {
      // Here you can implement the code to download the image
      // For example, using a package like 'dio' to download the image
      // This is just an example placeholder, adjust as needed.
      print('Downloading image from: $imagePath');
      // You can implement the actual download logic here if needed
      // For example, using the dio package to download
    }
  }

  ColorFilter _getColorFilter() {
    if (filterSliderValue < 0.25) {
      return const ColorFilter.mode(
        Colors.transparent,
        BlendMode.multiply,
      );
    } else if (filterSliderValue < 0.5) {
      return const ColorFilter.mode(
        Colors.grey,
        BlendMode.saturation,
      );
    } else if (filterSliderValue < 0.75) {
      return ColorFilter.mode(
        Colors.brown.withOpacity(0.5),
        BlendMode.multiply,
      );
    } else {
      return ColorFilter.mode(
        Colors.white.withOpacity(0.3),
        BlendMode.dstATop,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: const Text(
            'Camera App',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        toolbarHeight: 60.0,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Weather Info Container
          Container(
            height: 100.0,
            color: Colors.blue,
            child: Center(
              child: Text(
                weatherInfo,
                style: const TextStyle(
                  fontSize: 20.0,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Camera Preview with Floating Action Buttons
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: controller == null
                        ? (cameras == null
                            ? const Center(child: CircularProgressIndicator())
                            : const Text('No camera available'))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: ColorFiltered(
                              colorFilter: _getColorFilter(),
                              child: CameraPreview(controller!),
                            ),
                          ),
                  ),
                ),
                // Floating Action Buttons
                Positioned(
                  bottom: 40.0,
                  left: MediaQuery.of(context).size.width * 0.5 - 65,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FloatingActionButton(
                        onPressed: _takePicture,
                        tooltip: 'Take Picture',
                        child: const Icon(Icons.camera),
                      ),
                      const SizedBox(width: 16.0),
                      FloatingActionButton(
                        onPressed: switchCamera,
                        tooltip: 'Switch Camera',
                        child: const Icon(Icons.switch_camera),
                      ),
                      const SizedBox(width: 16.0),
                      FloatingActionButton(
                        onPressed: downloadImage, // Button to download image
                        tooltip: 'Download Image',
                        child: const Icon(Icons.download),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Slider for selecting filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Slider(
              value: filterSliderValue,
              min: 0,
              max: 1,
              divisions: 4,
              label: _getFilterLabel(),
              onChanged: (double newValue) {
                setState(() {
                  filterSliderValue = newValue;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    if (filterSliderValue < 0.25) {
      return 'None';
    } else if (filterSliderValue < 0.5) {
      return 'Grayscale';
    } else if (filterSliderValue < 0.75) {
      return 'Sepia';
    } else {
      return 'Brightness';
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

late CameraDescription firstCamera;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  firstCamera = cameras.first;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUMOS - Blind Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 8,
            shadowColor: Colors.deepPurple.withOpacity(0.3),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.deepPurple.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceCommand = "";
  bool _flashOn = false;

  Future<void> _toggleFlash() async {
    try {
      if (_flashOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() => _flashOn = !_flashOn);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Torch not available: $e")));
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() => _voiceCommand = val.recognizedWords);
        if (!_speech.isListening) {
          _handleVoiceCommand(_voiceCommand);
        }
      });
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    final pattern = RegExp(r'from[: ](.*?)to[: ](.*)', caseSensitive: false);
    final match = pattern.firstMatch(command);
    if (match != null) {
      final from = Uri.encodeComponent(match.group(1)!.trim());
      final to = Uri.encodeComponent(match.group(2)!.trim());
      final url = 'https://www.google.com/maps/dir/?api=1&origin=$from&destination=$to&travelmode=walking';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Say: 'From <place> To <place>'")));
    }
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A0B2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // App Title with Animation
                  Text(
                    "LUMOS",
                    style: GoogleFonts.orbitron(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                      shadows: [
                        const Shadow(
                          blurRadius: 20,
                          color: Colors.deepPurpleAccent,
                          offset: Offset(0, 0),
                        ),
                        const Shadow(
                          blurRadius: 40,
                          color: Colors.blueAccent,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1000.ms).scale(),
                  
                  const SizedBox(height: 20),
                  
                  // Subtitle
                  Text(
                    "Your Vision Assistant",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 800.ms),
                  
                  const SizedBox(height: 30),

                  // Main Action Cards
                  _buildActionCard(
                    context,
                    icon: Icons.visibility,
                    title: "My Surroundings",
                    subtitle: "Object recognition",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveVision(camera: firstCamera),
                        ),
                      );
                    },
                  ).animate().slideX(delay: 200.ms, duration: 600.ms),
                  
                  const SizedBox(height: 20),
                  
                  _buildActionCard(
                    context,
                    icon: _flashOn ? Icons.flash_off : Icons.flash_on,
                    title: _flashOn ? "Turn Off Flashlight" : "Turn On Flashlight",
                    subtitle: _flashOn ? "Flashlight is ON" : "Tap to enable flashlight",
                    gradient: _flashOn 
                        ? const LinearGradient(colors: [Color(0xFFff6b6b), Color(0xFFee5a24)])
                        : const LinearGradient(colors: [Color(0xFF4ecdc4), Color(0xFF44a08d)]),
                    onTap: _toggleFlash,
                  ).animate().slideX(delay: 400.ms, duration: 600.ms),
                  
                  const SizedBox(height: 20),
                  
                  _buildActionCard(
                    context,
                    icon: Icons.navigation,
                    title: "Voice Navigation",
                    subtitle: _isListening ? "Listening..." : "Say 'From A to B' ",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    onTap: _isListening ? null : _startListening,
                    isListening: _isListening,
                  ).animate().slideX(delay: 600.ms, duration: 600.ms),
                  
                  const SizedBox(height: 20),
                  
                  // Maps Button
                  _buildActionCard(
                    context,
                    icon: Icons.map,
                    title: "Open Maps",
                    subtitle: "Navigation with Maps",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapsPage(),
                        ),
                      );
                    },
                  ).animate().slideX(delay: 800.ms, duration: 600.ms),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback? onTap,
    bool isListening = false,
  }) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isListening)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                    .scale(duration: 500.ms)
                    .then()
                    .scale(duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🗺️ Maps Page with Google Maps Integration
class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  String _destination = "";
  final TextEditingController _destinationController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _markers.add(
            Marker(
              markerId: const MarkerId('current'),
              position: _currentPosition!,
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _startVoiceSearch() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() => _destination = val.recognizedWords);
        if (!_speech.isListening) {
          _searchDestination(_destination);
        }
      });
    }
  }

  Future<void> _searchDestination(String destination) async {
    if (destination.isNotEmpty) {
      setState(() => _destination = destination);
      _destinationController.text = destination;
      // Here you would typically use Google Places API to get coordinates
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Searching for: $destination')),
      );
    }
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Navigation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? null : _startVoiceSearch,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A0A), Color(0xFF1A0B2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _destinationController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search destination...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _isListening
                      ? const Icon(Icons.mic, color: Colors.red)
                      : IconButton(
                          icon: const Icon(Icons.mic_none, color: Colors.white70),
                          onPressed: _startVoiceSearch,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: _searchDestination,
              ),
            ),
            
            // Map
            Expanded(
              child: _currentPosition == null
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 15,
                      ),
                      markers: _markers,
                      mapType: MapType.normal,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔍 LiveVision Page (Enhanced)
class LiveVision extends StatefulWidget {
  final CameraDescription camera;
  const LiveVision({required this.camera});

  @override
  State<LiveVision> createState() => _LiveVisionState();
}

class _LiveVisionState extends State<LiveVision> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final FlutterTts _tts = FlutterTts();
  bool _isRunning = false;
  String _description = "";
  String _status = "Ready to start";
  bool _isProcessing = false;
  Timer? _timer;

  final String serverUrl = "http://192.168.68.53:3000/describe";

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> captureAndDescribe() async {
    if (!_controller.value.isInitialized || !_isRunning || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = "Analyzing image...";
    });

    try {
      final picture = await _controller.takePicture();
      final bytes = await picture.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageBase64': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final desc = data['description'] ?? "No objects detected.";

        if (desc != _description) {
          setState(() {
            _description = desc;
            _status = "Object detected!";
          });
          _tts.speak(desc);
        }
      } else {
        setState(() => _status = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _status = "Error: ${e.toString().substring(0, 50)}...");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void startVision() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => captureAndDescribe());
    setState(() {
      _isRunning = true;
      _status = "Vision started - Point camera at objects";
    });
  }

  void stopVision() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _status = "Vision stopped";
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Object Recognition',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0A0A), Color(0xFF1A0B2E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
              children: [
                  // Camera Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      child: CameraPreview(_controller),
                    ),
                  ),
                  
                  // Status Indicator
                Positioned(
                    top: 80,
                  left: 20,
                  right: 20,
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: 60,
                      borderRadius: 20,
                      blur: 20,
                      alignment: Alignment.bottomCenter,
                      border: 2,
                      linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _isProcessing
                              ? Colors.orange.withOpacity(0.2)
                              : _isRunning
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                          _isProcessing
                              ? Colors.orange.withOpacity(0.1)
                              : _isRunning
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      child: Center(
                    child: Text(
                          _status,
                          style: GoogleFonts.poppins(
                        color: Colors.white,
                            fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ),
                  ),
                ),

                  // Object Description
                  if (_description.isNotEmpty)
                    Positioned(
                      top: 160,
                      left: 20,
                      right: 20,
                      child: GlassmorphicContainer(
                        width: double.infinity,
                        height: 120,
                        borderRadius: 20,
                        blur: 20,
                        alignment: Alignment.bottomCenter,
                        border: 2,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepPurple.withOpacity(0.2),
                            Colors.blue.withOpacity(0.1),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "OBJECT DETECTED",
                                style: GoogleFonts.poppins(
                                  color: Colors.yellowAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _description,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Control Button
                Positioned(
                  bottom: 50,
                    left: 50,
                    right: 50,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isRunning 
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.green.shade400, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRunning ? Colors.red : Colors.green).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isProcessing ? null : (_isRunning ? stopVision : startVision),
                          borderRadius: BorderRadius.circular(35),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isProcessing)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Icon(
                                    _isRunning ? Icons.stop : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                const SizedBox(width: 12),
                                Text(
                                  _isRunning ? "STOP VISION" : "START VISION",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0A0A), Color(0xFF1A0B2E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurple,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

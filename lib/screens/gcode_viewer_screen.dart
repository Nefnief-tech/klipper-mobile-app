import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GCodeViewerScreen extends StatefulWidget {
  final String fileName;
  final String gcodeUrl;

  const GCodeViewerScreen({
    super.key,
    required this.fileName,
    required this.gcodeUrl,
  });

  @override
  State<GCodeViewerScreen> createState() => _GCodeViewerScreenState();
}

class _GCodeViewerScreenState extends State<GCodeViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _gcodeContent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (_gcodeContent != null) {
              _injectGCode();
            }
          },
        ),
      );
    _fetchGCode();
  }

  Future<void> _fetchGCode() async {
    try {
      final response = await http.get(Uri.parse(widget.gcodeUrl));
      if (response.statusCode == 200) {
        setState(() {
          _gcodeContent = response.body;
          _controller.loadHtmlString(_buildHtml());
        });
      } else {
        setState(() {
          _error = "Failed to load G-code: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _isLoading = false;
      });
    }
  }

  void _injectGCode() {
    final escapedGCode = jsonEncode(_gcodeContent);
    _controller.runJavaScript('loadGCodeFromContent($escapedGCode);');
    setState(() {
      _isLoading = false;
    });
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <style>
        body { margin: 0; background: #000000; color: white; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; overflow: hidden; }
        #container { width: 100vw; height: 100vh; position: relative; }
        canvas { width: 100% !important; height: 100% !important; outline: none; }
        
        #overlay {
            position: absolute;
            bottom: 24px;
            left: 24px;
            right: 24px;
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            padding: 16px 20px;
            pointer-events: none;
            display: none;
        }
        .stat-row { display: flex; justify-content: space-between; margin-bottom: 4px; }
        .stat-label { font-size: 10px; color: rgba(255,255,255,0.5); font-weight: bold; text-transform: uppercase; }
        .stat-value { font-size: 12px; font-family: monospace; color: #8A3FD6; }
    </style>
    <script src="https://unpkg.com/three@0.132.2/build/three.min.js"></script>
    <script src="https://unpkg.com/three@0.132.2/examples/js/loaders/GCodeLoader.js"></script>
    <script src="https://unpkg.com/three@0.132.2/examples/js/controls/OrbitControls.js"></script>
</head>
<body>
    <div id="container">
        <div id="viewer"></div>
        <div id="overlay">
            <div class="stat-row">
                <span class="stat-label">Dimensions</span>
                <span id="dim-val" class="stat-value">---</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">Model Height</span>
                <span id="height-val" class="stat-value">---</span>
            </div>
        </div>
    </div>
    <script>
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x0a0a0f);
        
        // Fog for depth
        scene.fog = new THREE.Fog(0x0a0a0f, 100, 1000);

        const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 10000);
        const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
        renderer.setPixelRatio(window.devicePixelRatio);
        renderer.setSize(window.innerWidth, window.innerHeight);
        document.getElementById('viewer').appendChild(renderer.domElement);

        const controls = new THREE.OrbitControls(camera, renderer.domElement);
        controls.enableDamping = true;
        controls.dampingFactor = 0.05;

        // Print Bed Grid
        const grid = new THREE.GridHelper(250, 25, 0x8A3FD6, 0x222222);
        grid.rotation.x = Math.PI / 2; // G-code loader usually treats Z as up, but Three.js Y is up by default
        scene.add(grid);

        const loader = new THREE.GCodeLoader();

        window.loadGCodeFromContent = function(content) {
            try {
                const object = loader.parse(content);
                
                // GCodeLoader output often needs rotation to sit on the grid
                // Assuming standard Z-up from Gcode
                scene.add(object);
                
                const box = new THREE.Box3().setFromObject(object);
                const center = box.getCenter(new THREE.Vector3());
                const size = box.getSize(new THREE.Vector3());
                
                // Update UI Overlay
                document.getElementById('overlay').style.display = 'block';
                document.getElementById('dim-val').innerText = `\${size.x.toFixed(1)} x \${size.y.toFixed(1)} mm`;
                document.getElementById('height-val').innerText = `\${size.z.toFixed(1)} mm`;

                const maxDim = Math.max(size.x, size.y, size.z);
                camera.position.set(0, -maxDim * 1.5, maxDim * 1.2);
                controls.target.set(center.x, center.y, center.z);
                controls.update();
            } catch (e) {
                console.error("Parse error:", e);
            }
        };

        // Lighting
        const hemiLight = new THREE.HemisphereLight(0xffffff, 0x444444, 1);
        scene.add(hemiLight);

        const dirLight = new THREE.DirectionalLight(0xffffff, 0.5);
        dirLight.position.set(50, -50, 100);
        scene.add(dirLight);

        function animate() {
            requestAnimationFrame(animate);
            controls.update();
            renderer.render(scene, camera);
        }
        animate();

        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1020),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("G-CODE VIEWER", style: GoogleFonts.anton(fontSize: 18, letterSpacing: 1)),
            Text(widget.fileName, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: _error != null 
        ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))))
        : WebViewWidget(controller: _controller),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          _fetchGCode();
        },
        child: const Icon(LucideIcons.refreshCw),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
      });
    });
    _checkPermissionsAndServices();
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    if (_isScanning) {
      FlutterBluePlus.stopScan();
    }
    super.dispose();
  }

  Future<void> _checkPermissionsAndServices() async {
    // Check Bluetooth permissions
    if (await Permission.bluetooth.isDenied ||
        await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
    }

    // Check location permissions
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    // Check if location services are enabled
    if (!(await Permission.location.serviceStatus.isEnabled)) {
      _showEnableLocationDialog();
    }
  }

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Location Services'),
        content: const Text(
            'Location services must be enabled to scan for Bluetooth devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    await _checkPermissionsAndServices();

    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );

    FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult result in results) {
        // Only add if not already in the list
        if (!_scanResults.contains(result)) {
          setState(() {
            _scanResults.add(result);
          });
        }
      }
    }, onError: (e) => print("Scan Error: $e"));

    // Stop scanning after a delay if not already stopped
    await Future.delayed(const Duration(seconds: 15));
    if (_isScanning) {
      _stopScan();
    }
  }

  void _stopScan() {
    if (!_isScanning) return;
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
        actions: [
          if (_adapterState == BluetoothAdapterState.on)
            IconButton(
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              onPressed: _isScanning ? _stopScan : _startScan,
            ),
        ],
      ),
      body: _adapterState == BluetoothAdapterState.on
          ? _buildScanResults()
          : _buildBluetoothOffScreen(),
    );
  }

  Widget _buildBluetoothOffScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Bluetooth is OFF',
            style: TextStyle(fontSize: 18),
          ),
          Text('Please turn on Bluetooth to scan for devices.'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/average');
            },
            child: const Text("Go to average calculation"),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResults() {
    return Column(
      children: [
        if (_isScanning) const LinearProgressIndicator(),
        Expanded(
          child: _scanResults.isEmpty
              ? const Center(
                  child: Text(
                    'No devices found. Tap "Search" to start scanning.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _scanResults.length,
                  itemBuilder: (context, index) {
                    final result = _scanResults[index];
                    return ListTile(
                      title: Text(
                        result.device.name.isNotEmpty
                            ? result.device.name
                            : 'Unknown Device',
                      ),
                      subtitle: Text(result.device.id.toString()),
                      onTap: () {
                        _connectToDevice(result.device);
                      },
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/average');
            },
            child: const Text("Go to average calculation"),
          ),
        ),
      ],
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecting to ${device.name}...')),
      );
    });

    try {
      await device.connect();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.name}')),
        );
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to ${device.name}')),
        );
      });
    }
  }
}

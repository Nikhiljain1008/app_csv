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
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    if (_isScanning) {
      FlutterBluePlus.stopScan();
    }
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: 15),
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
    await Future.delayed(Duration(seconds: 15));
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
        children: const [
          Icon(Icons.bluetooth_disabled, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Bluetooth is OFF',
            style: TextStyle(fontSize: 18),
          ),
          Text('Please turn on Bluetooth to scan for devices.'),
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
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/average');
          },
          child: const Text("Go to avarage calculation"),
        )
      ],
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // Ensure that the Scaffold is available when trying to show SnackBar
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

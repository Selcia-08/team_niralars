import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/shipment_provider.dart';
import '../../providers/location_provider.dart';

/// Create New Shipment Screen with Location Picker
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Location coordinates
  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  // Cargo type dropdown
  String _selectedCargoType = 'Electronics';
  final List<String> _cargoTypes = [
    'Electronics',
    'Industrial Machinery',
    'Textiles',
    'Automotive Parts',
    'FMCG Products',
    'Pharmaceuticals',
    'Steel & Metal',
    'Agricultural Products',
    'Furniture',
  ];

  // Priority
  String _priority = 'LOW';

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation(bool isPickup) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationPickerScreen(
          title: isPickup ? 'Select Pickup Location' : 'Select Drop Location',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupLat = result['lat'];
          _pickupLng = result['lng'];
          _pickupController.text = result['address'] ?? 'Selected location';
        } else {
          _dropLat = result['lat'];
          _dropLng = result['lng'];
          _dropController.text = result['address'] ?? 'Selected location';
        }
      });
    }
  }

  Future<void> _createShipment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupLat == null || _dropLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and drop locations on the map'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final provider = context.read<ShipmentProvider>();
    final success = await provider.createShipment(
      pickupLocation: _pickupController.text,
      pickupLat: _pickupLat!,
      pickupLng: _pickupLng!,
      dropLocation: _dropController.text,
      dropLat: _dropLat!,
      dropLng: _dropLng!,
      cargoType: _selectedCargoType,
      cargoWeight: double.tryParse(_weightController.text) ?? 0,
      priority: _priority,
      specialInstructions: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to create shipment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Shipment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ShipmentProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup & Delivery', style: AppTextStyles.heading3),
                  const SizedBox(height: 16),

                  // Pickup location picker
                  GestureDetector(
                    onTap: () => _selectLocation(true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _pickupController,
                        decoration: InputDecoration(
                          labelText: 'Pickup Location',
                          hintText: 'Tap to select on map',
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: AppColors.success,
                          ),
                          suffixIcon: _pickupLat != null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : const Icon(Icons.map_rounded),
                        ),
                        validator: (v) => v?.isEmpty == true
                            ? 'Select pickup location'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Drop location picker
                  GestureDetector(
                    onTap: () => _selectLocation(false),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dropController,
                        decoration: InputDecoration(
                          labelText: 'Drop Location',
                          hintText: 'Tap to select on map',
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: AppColors.error,
                          ),
                          suffixIcon: _dropLat != null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : const Icon(Icons.map_rounded),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Select drop location' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Cargo Details', style: AppTextStyles.heading3),
                  const SizedBox(height: 16),

                  // Cargo type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCargoType,
                    decoration: const InputDecoration(
                      labelText: 'Cargo Type',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _cargoTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCargoType = v!),
                  ),
                  const SizedBox(height: 16),

                  // Weight input
                  TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight (tonnes)',
                      hintText: 'e.g., 2.5',
                      prefixIcon: Icon(Icons.scale_rounded),
                    ),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Required';
                      final weight = double.tryParse(v!);
                      if (weight == null || weight < 0.1 || weight > 50) {
                        return 'Weight must be 0.1 - 50 tonnes';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  Text('Priority', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Row(
                    children: ['LOW', 'MEDIUM', 'HIGH'].map((p) {
                      final isSelected = _priority == p;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _priority = p),
                          child: Container(
                            margin: EdgeInsets.only(right: p != 'HIGH' ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                p,
                                style: AppTextStyles.caption.copyWith(
                                  color: isSelected
                                      ? AppColors.background
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Special instructions
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Special Instructions (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _createShipment,
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : const Text('Create Shipment'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Location Picker Screen with Google Maps
class _LocationPickerScreen extends StatefulWidget {
  final String title;

  const _LocationPickerScreen({required this.title});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  LatLng? _selectedLocation;
  String _address = '';

  @override
  void initState() {
    super.initState();
    // Get current location as initial center
    final loc = context.read<LocationProvider>();
    if (loc.currentPosition != null) {
      _selectedLocation = LatLng(
        loc.currentPosition!.latitude,
        loc.currentPosition!.longitude,
      );
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _address =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    });
  }

  void _confirmSelection() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap on the map to select a location'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'lat': _selectedLocation!.latitude,
      'lng': _selectedLocation!.longitude,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocationProvider>();
    final initialPosition = loc.currentPosition != null
        ? LatLng(loc.currentPosition!.latitude, loc.currentPosition!.longitude)
        : const LatLng(19.0760, 72.8777); // Mumbai as default

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 14,
            ),
            onTap: _onMapTap,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_address, style: AppTextStyles.body)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

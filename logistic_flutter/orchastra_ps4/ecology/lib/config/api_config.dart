/// API Configuration for EcoLogiq Logistics App
class ApiConfig {
  // Base URL - Change this for production
  static const String baseUrl =
      'https://eco-logistics-production.up.railway.app'; // Production
  // static const String baseUrl = 'http://localhost:3000'; // iOS simulator
  // static const String baseUrl = 'http://YOUR_IP:3000'; // Physical device

  // Auth endpoints
  static const String sendOtp = '/api/auth/login';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String profile = '/api/auth/profile';
  static const String refreshToken = '/api/auth/refresh-token';

  // Delivery endpoints
  static const String assignedDeliveries = '/api/deliveries/assigned';
  static const String createDelivery = '/api/deliveries/create';
  static const String acceptDelivery = '/api/deliveries'; // /:id/accept
  static const String startDelivery = '/api/deliveries'; // /:id/start
  static const String pickupCargo = '/api/deliveries'; // /:id/pickup
  static const String completeDelivery = '/api/deliveries'; // /:id/complete
  static const String uploadPhotos = '/api/deliveries'; // /:id/upload-photos

  // Shipment endpoints
  static const String createShipment = '/api/shipments/create';
  static const String myShipments = '/api/shipments/my-shipments';
  static const String shipmentById = '/api/shipments'; // /:id
  static const String pendingShipments =
      '/api/shipments/pending'; // For drivers
  static const String acceptShipment = '/api/shipments'; // /:id/accept

  // Synergy/Absorption endpoints
  static const String generateQR = '/api/synergy/generate-qr';
  static const String verifyQR = '/api/synergy/verify-qr';
  static const String completeHandover = '/api/synergy/complete-handover';

  // Backhaul endpoints
  static const String backhaulOpportunities = '/api/backhaul/opportunities';
  static const String checkBackhaulOpportunities =
      '/api/backhaul/check-opportunities';
  static const String acceptBackhaul = '/api/backhaul'; // /:id/accept

  // Dashboard endpoints
  static const String dashboardStats = '/api/dashboard/stats';
  static const String transactions = '/api/transactions';

  // Driver endpoints
  static const String updateLocation = '/api/drivers/location';
  static const String activeRoute = '/api/drivers'; // /:truckId/active-route

  // Truck endpoints
  static const String trucks = '/api/trucks';

  // E-Way Bill endpoints
  static const String ewayBills = '/api/eway-bill';
  static const String generateEwayBill = '/api/eway-bill/generate';
  static const String downloadEwayBill = '/api/eway-bill'; // /:id/download

  // Google Maps API Key
  static const String googleMapsApiKey =
      'AIzaSyBHPaXU2EnkP03KTLJZ4PXrt0Je5ci2RJI';

  // Socket.io URL
  static const String socketUrl = baseUrl;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

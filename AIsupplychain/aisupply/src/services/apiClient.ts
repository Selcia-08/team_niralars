import axios from "axios";

// Create a centralized Axios instance
const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "http://localhost:3000/api", // Configure this based on your backend URL
  headers: {
    "Content-Type": "application/json",
  },
});

// Add request interceptor to include auth token
apiClient.interceptors.request.use((config) => {
  // Try to get token from localStorage or dev_token.json
  const token = localStorage.getItem("authToken");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// --- Authentication ---
export const sendOTP = async (
  phone: string,
  role: "DRIVER" | "SHIPPER" | "DISPATCHER" = "DISPATCHER",
) => {
  const response = await apiClient.post("/auth/login", {
    phone,
    role,
  });
  return response.data;
};

export const verifyOTP = async (
  phone: string,
  otp: string,
  role: "DRIVER" | "SHIPPER" | "DISPATCHER" = "DISPATCHER",
) => {
  const response = await apiClient.post("/auth/verify-otp", {
    phone,
    otp,
    role,
  });
  return response.data;
};

export const getProfile = async () => {
  const response = await apiClient.get("/auth/profile");
  return response.data;
};

export const refreshToken = async (refreshToken: string) => {
  const response = await apiClient.post("/auth/refresh-token", {
    refreshToken,
  });
  return response.data;
};

// --- Dashboard ---
export const getDashboardStats = async () => {
  const response = await apiClient.get("/dashboard/stats");
  return response.data;
};

export const getDashboardActivity = async () => {
  const response = await apiClient.get("/dashboard/activity");
  return response.data;
};

export const getLiveTracking = async () => {
  const response = await apiClient.get("/dashboard/live-tracking-web");
  return response.data;
};

export const getLiveTrackingGPS = async () => {
  const response = await apiClient.get("/dashboard/live-tracking-gps");
  return response.data;
};

export const getActiveRoute = async (truckId: string) => {
  const response = await apiClient.get(`/drivers/${truckId}/active-route`);
  return response.data;
};

export const getRecentAbsorptions = async () => {
  const response = await apiClient.get("/dashboard/recent-absorptions");
  return response.data;
};

// --- Drivers
export const getAllDrivers = async () => {
  const response = await apiClient.get("/drivers");
  return response.data;
};

export const getDriverById = async (id: string) => {
  const response = await apiClient.get(`/drivers/${id}`);
  return response.data;
};

export const createDriver = async (driverData: any) => {
  const response = await apiClient.post("/drivers", driverData);
  return response.data;
};

export const updateDriver = async (id: string, driverData: any) => {
  const response = await apiClient.put(`/drivers/${id}`, driverData);
  return response.data;
};

export const deleteDriver = async (id: string) => {
  const response = await apiClient.delete(`/drivers/${id}`);
  return response.data;
};

// --- Absorption Requests ---
export const getAllRequests = async () => {
  const response = await apiClient.get("/absorption/active");
  return response.data;
};

export const updateRequestStatus = async (
  id: string,
  action: "APPROVED" | "REJECTED",
) => {
  const endpoint =
    action === "APPROVED"
      ? "/synergy/dispatcher-accept"
      : "/synergy/dispatcher-reject";
  const response = await apiClient.post(endpoint, {
    opportunityId: id,
    dipatcherId: "819f1587-5cc8-41bb-921c-1312c5249b24",
  });
  return response.data;
};

export const getRecommendedDrivers = async (id: string) => {
  const response = await apiClient.get(
    `/absorption-requests/${id}/recommendations`,
  );
  return response.data;
};

// --- Absorption (New) ---
export const getAbsorptionMapData = async () => {
  const response = await apiClient.get("/absorption/map-data");
  return response.data;
};

export const getActiveAbsorptions = async () => {
  const response = await apiClient.get("/absorption/active");
  return response.data;
};

// --- E-Way Bills ---
export const getAllBills = async () => {
  const response = await apiClient.get("/eway-bills");
  return response.data;
};

export const createBill = async (billData: any) => {
  const response = await apiClient.post("/eway-bills", billData);
  return response.data;
};

export const getEWayBillsStats = async () => {
  const response = await apiClient.get("/eway-bills/stats");
  return response.data;
};

export const updateEWayBill = async (id: string, billData: any) => {
  const response = await apiClient.put(`/eway-bills/${id}`, billData);
  return response.data;
};

export const deleteEWayBill = async (id: string) => {
  const response = await apiClient.delete(`/eway-bills/${id}`);
  return response.data;
};

// --- Packages ---
export const getPackageHistory = async () => {
  const response = await apiClient.get("/packages/history-web");
  return response.data;
};

// Add Auth Interceptor
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// --- Shipments (Packages) ---
export const createShipment = async (shipmentData: any) => {
  const response = await apiClient.post("/shipments/create", shipmentData);
  return response.data;
};

export const getMyShipments = async () => {
  const response = await apiClient.get("/shipments/my-shipments");
  return response.data;
};

// --- Deliveries ---
export const createDelivery = async (deliveryData: any) => {
  const response = await apiClient.post("/deliveries/create", deliveryData);
  return response.data;
};

export const getUnassignedDeliveries = async (courierCompanyId: string) => {
  const response = await apiClient.get(
    `/deliveries/unassigned?courierCompanyId=20c97585-a16d-45e7-8d5f-0ef5ce85b896`,
  );
  return response.data;
};

export const assignMultiStopTask = async (payload: any) => {
  const response = await apiClient.post("/routes/assign-multi-stop", payload);
  return response.data;
};

// --- Virtual Hubs ---
export const getAllVirtualHubs = async () => {
  const response = await apiClient.get("/virtual-hubs");
  return response.data;
};

export const createVirtualHub = async (hubData: any) => {
  const response = await apiClient.post("/virtual-hubs", hubData);
  return response.data;
};

export const deleteVirtualHub = async (id: string) => {
  const response = await apiClient.delete(`/virtual-hubs/${id}`);
  return response.data;
};

export default apiClient;

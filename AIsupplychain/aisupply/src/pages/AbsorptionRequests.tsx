import { useState, useEffect } from "react";
import { CheckCircle, XCircle, Clock, AlertCircle } from "lucide-react";
import { AbsorptionMap } from "../components/AbsorptionMap";
import { useToast } from "../context/ToastContext";
import {
  getAllRequests,
  getRecommendedDrivers,
  updateRequestStatus,
} from "../services/apiClient";

export function AbsorptionRequests() {
  const { showToast } = useToast();
  const [requests, setRequests] = useState<any[]>([]);
  const [activeRequest, setActiveRequest] = useState<any | null>(null);
  const [recommendedDrivers, setRecommendedDrivers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Helper to refresh data
  const fetchData = async () => {
    try {
      setLoading(true);
      const requestsData = await getAllRequests();

      // Filter: Show only PENDING absorption opportunities (case-insensitive)
      const validRequests = requestsData.filter(
        (r: any) => r.status?.toUpperCase() === "PENDING",
      );

      console.log("Valid requests filtered:", validRequests);
      setRequests(validRequests);

      // Set the first active request if available
      if (validRequests.length > 0) {
        // If we already selected one that is still valid, keep it. Otherwise pick first.
        const currentValid =
          activeRequest &&
          validRequests.find((r: any) => r.id === activeRequest.id);
        const nextActive = currentValid || validRequests[0];

        setActiveRequest(nextActive);

        // Fetch recommended drivers for the active request
        if (nextActive?.id) {
          try {
            const drivers = await getRecommendedDrivers(nextActive.id);
            setRecommendedDrivers(drivers);
          } catch (err) {
            console.error("Failed to fetch recommended drivers:", err);
            setRecommendedDrivers([]);
          }
        }
      } else {
        setActiveRequest(null);
        setRecommendedDrivers([]);
      }
      setError(null);
    } catch (err: any) {
      console.error("Failed to fetch absorption requests:", err);
      setError("Failed to load absorption requests. Check backend connection.");
      showToast(
        "Connection Error",
        "Unable to fetch absorption requests",
        "error",
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [showToast]);

  const handleStatusUpdate = async (action: "APPROVED" | "REJECTED") => {
    if (!activeRequest) return;

    try {
      await updateRequestStatus(activeRequest.id, action);
      showToast(
        "Success",
        `Request ${action === "APPROVED" ? "Approved" : "Rejected"}`,
        "success",
      );
      // Refresh list to remove the processed item
      await fetchData();
    } catch (error) {
      console.error("Update failed:", error);
      showToast("Error", "Failed to update request status", "error");
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-eco-brand-orange"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-[60vh] text-center px-4">
        <AlertCircle className="w-12 h-12 text-eco-error mb-4" />
        <h3 className="text-xl font-semibold text-white mb-2">Unavailable</h3>
        <p className="text-eco-text-secondary">{error}</p>
      </div>
    );
  }

  if (!activeRequest) {
    return (
      <div className="flex flex-col items-center justify-center h-[60vh] text-center px-4 text-eco-text-secondary">
        <CheckCircle className="w-16 h-16 text-eco-success mb-4 opacity-50" />
        <h3 className="text-xl font-semibold text-white mb-2">All Caught Up</h3>
        <p>No pending absorption requests from the last 24 hours.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center text-sm text-eco-text-secondary mb-2">
        Dashboard <span className="mx-2">&gt;</span>{" "}
        <span className="text-white font-semibold">Absorption Requests</span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 h-[calc(100vh-140px)]">
        {/* Requests List */}
        <div className="bg-eco-card rounded-xl border border-eco-card-border p-4 overflow-y-auto custom-scrollbar">
          <h3 className="text-white font-semibold mb-4">
            Pending Requests ({requests.length})
          </h3>
          <div className="space-y-3">
            {requests.map((request: any) => (
              <div
                key={request.id}
                onClick={() => {
                  setActiveRequest(request);
                  if (request.id) {
                    getRecommendedDrivers(request.id)
                      .then(setRecommendedDrivers)
                      .catch(() => setRecommendedDrivers([]));
                  }
                }}
                className={`p-3 rounded-lg border cursor-pointer transition-all ${
                  activeRequest?.id === request.id
                    ? "bg-eco-brand-orange/20 border-eco-brand-orange/50 shadow-neon-orange"
                    : "border-eco-card-border hover:border-eco-brand-orange/30 hover:bg-eco-secondary/50"
                }`}
              >
                <div className="text-sm font-semibold text-eco-brand-orange">
                  {request.displayId}
                </div>
                <div className="text-xs text-gray-400 mt-1">
                  {request.truck1 || "Truck 1"} → {request.truck2 || "Truck 2"}
                </div>
                <div className="text-xs text-white mt-1">
                  Weight: {request.weight}
                </div>
                <div
                  className={`text-xs mt-2 px-2 py-0.5 rounded w-fit ${
                    request.priority === "HIGH"
                      ? "bg-red-500/20 text-red-400"
                      : "bg-orange-500/20 text-orange-400"
                  }`}
                >
                  {request.priority || "MEDIUM"}
                </div>
              </div>
            ))}
            {requests.length === 0 && (
              <div className="text-center text-gray-400 text-sm py-8">
                No pending requests
              </div>
            )}
          </div>
        </div>

        {/* Map and Details */}
        <div className="lg:col-span-3 space-y-6 flex flex-col">
          {/* Map Area */}
          <div className="bg-eco-card rounded-xl border border-eco-card-border p-6 relative overflow-hidden flex flex-col flex-1">
            <h2 className="text-lg font-semibold text-white mb-4">
              Live Route Visualization
            </h2>
            <div className="flex-1 rounded-xl overflow-hidden border border-eco-card-border">
              <AbsorptionMap />
            </div>
          </div>

          {/* Details Panel */}
          <div className="space-y-4 overflow-y-auto pr-2 custom-scrollbar flex-1">
            {/* Request Card */}
            <div className="bg-eco-card rounded-xl border border-eco-brand-orange/30 p-6 shadow-neon-orange relative overflow-hidden">
              <div className="absolute top-0 right-0 w-24 h-24 bg-eco-brand-orange/5 rounded-full blur-2xl transform translate-x-8 -translate-y-8"></div>

              <div className="flex justify-between items-start mb-4 relative">
                <div>
                  <h3 className="text-eco-brand-orange font-bold text-lg">
                    Active Absorption Request
                  </h3>
                  <div className="text-eco-text-secondary text-sm">
                    {activeRequest?.displayId || "N/A"}
                  </div>
                </div>
                <span
                  className={`px-3 py-1 rounded-full text-xs font-medium border ${
                    activeRequest?.status?.toUpperCase() === "PENDING"
                      ? "bg-eco-brand-orange/10 text-eco-brand-orange border-eco-brand-orange/20 animate-pulse"
                      : "bg-gray-700/50 text-gray-400 border-gray-600"
                  }`}
                >
                  {activeRequest?.status || "N/A"}
                </span>
              </div>

              <div className="grid grid-cols-2 gap-3 mb-4 relative">
                <div className="bg-eco-secondary/50 p-2 rounded-lg">
                  <div className="text-xs text-gray-500">Weight</div>
                  <div className="text-white font-semibold">
                    {activeRequest?.weight || "-"}
                  </div>
                </div>
                <div className="bg-eco-secondary/50 p-2 rounded-lg">
                  <div className="text-xs text-gray-500">Type</div>
                  <div className="text-white font-semibold">
                    {activeRequest?.type || "-"}
                  </div>
                </div>
                <div className="bg-eco-secondary/50 p-2 rounded-lg">
                  <div className="text-xs text-gray-500">Truck 1</div>
                  <div className="text-white font-semibold text-sm">
                    {activeRequest?.truck1 || "-"}
                  </div>
                </div>
                <div className="bg-eco-secondary/50 p-2 rounded-lg">
                  <div className="text-xs text-gray-500">Truck 2</div>
                  <div className="text-white font-semibold text-sm">
                    {activeRequest?.truck2 || "-"}
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-center text-eco-brand-orange text-xs font-medium bg-eco-brand-orange/10 p-3 rounded-lg border border-eco-brand-orange/20 relative">
                <div className="text-center w-full">
                  <div>
                    Distance Saved:{" "}
                    <span className="text-white">
                      {activeRequest?.distanceSaved || 0}km
                    </span>
                  </div>
                  <div>
                    Carbon Saved:{" "}
                    <span className="text-white">
                      {activeRequest?.carbonSaved || 0}kg
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={() => handleStatusUpdate("APPROVED")}
                className="bg-eco-success hover:bg-emerald-600 text-white text-sm font-semibold py-3 rounded-lg shadow-neon flex items-center justify-center transition-all active:scale-[0.98]"
              >
                <CheckCircle className="w-4 h-4 mr-2" /> Approve
              </button>
              <button
                onClick={() => handleStatusUpdate("REJECTED")}
                className="bg-transparent border border-eco-error/30 text-eco-error hover:bg-eco-error/10 text-sm font-semibold py-3 rounded-lg flex items-center justify-center transition-colors active:scale-[0.98]"
              >
                <XCircle className="w-4 h-4 mr-2" /> Reject
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

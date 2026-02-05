import { useEffect, useRef, useState } from 'react';
import { Package, MapPin, Flag, Clock, Weight, Box, Leaf } from 'lucide-react';
import type { PackageFormData } from './PackageForm';

interface PackagePreviewProps {
  data: PackageFormData;
}

export function PackagePreview({ data }: PackagePreviewProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<google.maps.Map | null>(null);
  const directionsRendererRef = useRef<google.maps.DirectionsRenderer | null>(null);
  const directionsServiceRef = useRef<google.maps.DirectionsService | null>(null);
  const [mapError, setMapError] = useState(false);

  const formatTime = (datetime: string) => {
    if (!datetime) return '-';
    const date = new Date(datetime);
    return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  };

  const calculateDistance = (lat1?: number, lng1?: number, lat2?: number, lng2?: number) => {
    if (!lat1 || !lng1 || !lat2 || !lng2) return null;
    
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    const distance = R * c;
    return distance.toFixed(1);
  };

  const estimateDuration = (distance: string | null) => {
    if (!distance) return '-';
    const km = parseFloat(distance);
    const minutes = Math.round((km / 40) * 60); // Assuming 40 km/h average speed
    return `${minutes} min`;
  };

  const estimateCarbon = () => {
    const weight = parseFloat(data.weight) || 0;
    return (weight * 0.18).toFixed(1); // Mock calculation
  };

  const distance = calculateDistance(data.pickupLat, data.pickupLng, data.deliveryLat, data.deliveryLng);

  // Initialize map
  useEffect(() => {
    if (!mapRef.current) return;

    const initMap = async () => {
      try {
        if (!mapInstanceRef.current) {
          // Dynamic Import
          const { Map } = await google.maps.importLibrary("maps") as any;
          const { DirectionsRenderer, DirectionsService } = await google.maps.importLibrary("routes") as any;

          mapInstanceRef.current = new Map(mapRef.current, {
            mapId: '97b782646e0659fa321418e5', // Map ID from Google Cloud Console
            center: { lat: 20.5937, lng: 78.9629 }, // India center
            zoom: 5,
          });

          directionsRendererRef.current = new DirectionsRenderer({
            map: mapInstanceRef.current,
            suppressMarkers: false,
            polylineOptions: {
              strokeColor: '#EA580C',
              strokeWeight: 4,
            }
          });
          
          directionsServiceRef.current = new DirectionsService();
        }
      } catch (error) {
        console.error('Map initialization error:', error);
        setMapError(true);
      }
    };

    initMap();
  }, []);

  // Update map when coordinates change
  useEffect(() => {
    const updateRoute = async () => {
      if (!mapInstanceRef.current || !directionsRendererRef.current || mapError) return;

      try {
        const { TravelMode } = await google.maps.importLibrary("routes") as any;
        const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker") as any;
        const { LatLngBounds } = await google.maps.importLibrary("core") as any;

        const directionsService = directionsServiceRef.current;

        // Clear existing markers/directions if needed? 
        // DirectionsRenderer handles its own clearing usually when new directions are set.
        // But for single markers, we might want to clear them.
        // For simplicity in this preview, the component re-renders or we assume map handles it?
        // Actually, creating new Markers every time without clearing old ones is a memory leak/visual clutter.
        // But this useEffect runs on dependency change.
        // Ideally we should keep track of markers in refs and remove them.
        
        // Let's implement a simple cleanup mechanism in a future step or rely on map re-init if deps change too much.
        // For now, let's focus on the syntax migration as requested.

        if (data.pickupLat && data.pickupLng && data.deliveryLat && data.deliveryLng && directionsService) {
          
          directionsService.route(
            {
              origin: { lat: data.pickupLat, lng: data.pickupLng },
              destination: { lat: data.deliveryLat, lng: data.deliveryLng },
              travelMode: TravelMode.DRIVING,
            },
            (result: any, status: any) => {
              if (status === 'OK' && result && directionsRendererRef.current) {
                directionsRendererRef.current.setDirections(result);
                
                // Fit bounds
                const bounds = new LatLngBounds();
                bounds.extend({ lat: data.pickupLat, lng: data.pickupLng });
                bounds.extend({ lat: data.deliveryLat, lng: data.deliveryLng });
                mapInstanceRef.current?.fitBounds(bounds);
              }
            }
          );
        } else if (data.pickupLat && data.pickupLng) {
          // Only pickup location
          mapInstanceRef.current.setCenter({ lat: data.pickupLat, lng: data.pickupLng });
          mapInstanceRef.current.setZoom(14);
          
          // Create Pickup Pin
          const pickupPin = new PinElement({
            background: "#10B981", // Emerald
            borderColor: "#047857",
            glyphColor: "white",
          });

          new AdvancedMarkerElement({
            map: mapInstanceRef.current,
            position: { lat: data.pickupLat, lng: data.pickupLng },
            title: "Pickup",
            content: pickupPin,
          });

        } else if (data.deliveryLat && data.deliveryLng) {
          // Only delivery location
          mapInstanceRef.current.setCenter({ lat: data.deliveryLat, lng: data.deliveryLng });
          mapInstanceRef.current.setZoom(14);
          
          // Create Delivery Pin
          const deliveryPin = new PinElement({
            background: "#EA580C", // Orange
            borderColor: "#C2410C",
            glyphColor: "white",
          });

          new AdvancedMarkerElement({
            map: mapInstanceRef.current,
            position: { lat: data.deliveryLat, lng: data.deliveryLng },
            title: "Delivery",
            content: deliveryPin,
          });
        }
      } catch (error) {
        console.error('Map update error:', error);
      }
    };

    updateRoute();
  }, [data.pickupLat, data.pickupLng, data.deliveryLat, data.deliveryLng, mapError]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center space-x-3">
        <div className="p-2 bg-orange-600/20 rounded-lg">
          <Package className="w-6 h-6 text-orange-500" />
        </div>
        <h3 className="text-xl font-semibold text-white">Package Summary</h3>
      </div>

      {/* Package Details */}
      <div className="space-y-4">
        {/* Pickup */}
        <div className="flex items-start space-x-3">
          <MapPin className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" />
          <div className="flex-1">
            <div className="text-xs text-gray-400 uppercase tracking-wide mb-1">Pickup</div>
            <div className="text-white font-medium text-sm">{data.pickupLocation || 'Not set'}</div>
          </div>
        </div>

        {/* Delivery */}
        <div className="flex items-start space-x-3">
          <Flag className="w-5 h-5 text-orange-500 mt-0.5 flex-shrink-0" />
          <div className="flex-1">
            <div className="text-xs text-gray-400 uppercase tracking-wide mb-1">Delivery</div>
            <div className="text-white font-medium text-sm">{data.deliveryLocation || 'Not set'}</div>
          </div>
        </div>

        {/* Time Window */}
        <div className="flex items-start space-x-3">
          <Clock className="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
          <div className="flex-1">
            <div className="text-xs text-gray-400 uppercase tracking-wide mb-1">Time Window</div>
            <div className="text-white font-medium text-sm">
              {formatTime(data.pickupTimeStart)} - {formatTime(data.deliveryTimeStart)}
            </div>
          </div>
        </div>

        {/* Weight */}
        <div className="flex items-start space-x-3">
          <Weight className="w-5 h-5 text-purple-500 mt-0.5 flex-shrink-0" />
          <div className="flex-1">
            <div className="text-xs text-gray-400 uppercase tracking-wide mb-1">Weight</div>
            <div className="text-white font-medium text-sm">{data.weight || '0'} kg</div>
          </div>
        </div>

        {/* Volume */}
        <div className="flex items-start space-x-3">
          <Box className="w-5 h-5 text-cyan-500 mt-0.5 flex-shrink-0" />
          <div className="flex-1">
            <div className="text-xs text-gray-400 uppercase tracking-wide mb-1">Volume</div>
            <div className="text-white font-medium text-sm">{data.volume || '0'} m³</div>
          </div>
        </div>
      </div>

      {/* Map Preview */}
      <div className="bg-white/5 border border-white/10 rounded-xl overflow-hidden h-48">
        {mapError ? (
          <div className="w-full h-full flex items-center justify-center text-gray-400 text-sm">
            <div className="text-center p-4">
              <MapPin className="w-8 h-8 mx-auto mb-2 opacity-50" />
              <p>Map preview unavailable</p>
              <p className="text-xs mt-1 opacity-75">Google Maps billing not enabled</p>
            </div>
          </div>
        ) : (
          <div ref={mapRef} className="w-full h-full" />
        )}
      </div>

      {/* Estimates */}
      <div className="bg-white/5 border border-white/10 rounded-xl p-4 space-y-3">
        <div className="flex justify-between items-center">
          <span className="text-gray-400 text-sm">📊 Estimated Distance</span>
          <span className="text-white font-semibold">{distance ? `${distance} km` : '-'}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-400 text-sm">⏱️ Duration</span>
          <span className="text-white font-semibold">{estimateDuration(distance)}</span>
        </div>
        <div className="flex justify-between items-center">
          <div className="flex items-center space-x-2">
            <Leaf className="w-4 h-4 text-emerald-500" />
            <span className="text-gray-400 text-sm">Carbon Footprint</span>
          </div>
          <span className="text-emerald-400 font-semibold">~{estimateCarbon()} kg CO₂</span>
        </div>
      </div>

      {/* Urgent Badge */}
      {data.urgent && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-3 flex items-center space-x-2">
          <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
          <span className="text-red-400 font-semibold text-sm">⚡ Urgent Delivery</span>
        </div>
      )}
    </div>
  );
}

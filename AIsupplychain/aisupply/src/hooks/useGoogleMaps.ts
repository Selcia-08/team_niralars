import { useEffect, useRef } from 'react';

interface PlaceResult {
  address: string;
  lat: number;
  lng: number;
  displayName?: string;
  placeId?: string;
  raw?: any;
}

export function useGooglePlacesAutocomplete(
  containerRef: React.RefObject<HTMLDivElement | null>,
  onPlaceSelected: (place: PlaceResult) => void,
  initialValue?: string,
  inputId?: string,
  onLoaded?: () => void
) {
  const autocompleteInstanceRef = useRef<any>(null);
  
  // Use refs to keep callbacks fresh without triggering re-effects
  const onPlaceSelectedRef = useRef(onPlaceSelected);
  const onLoadedRef = useRef(onLoaded);

  useEffect(() => {
    onPlaceSelectedRef.current = onPlaceSelected;
    onLoadedRef.current = onLoaded;
  });

  useEffect(() => {
    let active = true;

    // Wait for the Google Maps API to load
    const initAutocomplete = async () => {
      // If container is missing, we can't do anything
      if (!containerRef.current) return;
      
      // If we already have an instance tracked, stop.
      if (autocompleteInstanceRef.current) {
        if (onLoadedRef.current) onLoadedRef.current();
        return;
      }

      // Double check: if container already has children, assume it's initialized
      if (containerRef.current.children.length > 0) {
        autocompleteInstanceRef.current = containerRef.current.firstElementChild;
        if (onLoadedRef.current) onLoadedRef.current();
        return;
      }

      try {
        // Import the library dynamically
        const { PlaceAutocompleteElement } = await google.maps.importLibrary("places") as any;
        
        if (!active) return; // Prevent appending if unmounted

        // Create the element programmatically
        const autocomplete = new PlaceAutocompleteElement();
        
        // Style the input within the web component
        autocomplete.classList.add('w-full');
        
        // set ID if provided (for label association)
        if (inputId) {
          // The web component host itself can take the ID
          autocomplete.id = inputId;
        }
        
        // Set initial value if provided
        if (initialValue) {
          autocomplete.value = initialValue;
        }

        // Append to container
        if (containerRef.current) {
             containerRef.current.appendChild(autocomplete);
             autocompleteInstanceRef.current = autocomplete;

             // Add event listener
             autocomplete.addEventListener('gmp-select', async (event: any) => {
               if (event.placePrediction) {
                 const place = event.placePrediction.toPlace();
                 
                 await place.fetchFields({
                   fields: ['displayName', 'formattedAddress', 'location'],
                 });

                 if (place.location && place.formattedAddress) {
                   // Call the stable ref
                   if (onPlaceSelectedRef.current) {
                     onPlaceSelectedRef.current({
                       address: place.formattedAddress,
                       lat: place.location.lat(),
                       lng: place.location.lng(),
                       displayName: place.displayName,
                       placeId: place.id,
                       raw: place
                     } as any);
                   }
                 }
               }
             });
             
             // Notify that we are loaded via stable ref
             if (onLoadedRef.current) onLoadedRef.current();
        }

      } catch (error) {
        console.error("Failed to initialize Place Autocomplete:", error);
      }
    };

    initAutocomplete();
    
    // Cleanup
    return () => {
      active = false;
      if (containerRef.current) {
        containerRef.current.innerHTML = '';
      }
      autocompleteInstanceRef.current = null;
    }
  }, [containerRef, inputId]); // Stable dependencies (removed callbacks)
}

export async function geocodeAddress(address: string): Promise<PlaceResult | null> {
  const { Geocoder } = await google.maps.importLibrary("geocoding") as any;
  const geocoder = new Geocoder();
  
  try {
    const result = await geocoder.geocode({ address });
    
    if (result.results[0]) {
      const location = result.results[0].geometry.location;
      return {
        address: result.results[0].formatted_address,
        lat: location.lat(),
        lng: location.lng(),
      };
    }
  } catch (error) {
    console.error('Geocoding error:', error);
  }
  
  return null;
}

export async function geocodeAddressManually(address: string): Promise<PlaceResult | null> {
  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(address)}&limit=1`,
      {
        headers: {
          'User-Agent': 'EcoLogiq-DeliveryApp/1.0'
        }
      }
    );
    
    const data = await response.json();
    
    if (data && data.length > 0) {
      return {
        address: data[0].display_name,
        lat: parseFloat(data[0].lat),
        lng: parseFloat(data[0].lon),
      };
    }
  } catch (error) {
    console.error('Manual geocoding error:', error);
  }
  
  return null;
}

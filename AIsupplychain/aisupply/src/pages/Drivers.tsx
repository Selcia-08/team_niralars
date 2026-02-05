import { useState, useMemo, useEffect, useRef } from 'react';
import { Search, Filter, Star, Truck, MapPin, Phone, MoreHorizontal, AlertCircle, Edit, Trash, Eye } from 'lucide-react';
import { useToast } from '../context/ToastContext';
import { getAllDrivers, createDriver, updateDriver, deleteDriver } from '../services/apiClient';
import { DriverDetailPanel } from '../components/DriverDetailPanel';
import { AddDriverModal } from '../components/AddDriverModal';

export function Drivers() {
    const { showToast } = useToast();
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState<string | null>(null);
    const [driversData, setDriversData] = useState<any[]>([]);
    const [selectedDriver, setSelectedDriver] = useState<any | null>(null);
    const [editingDriver, setEditingDriver] = useState<any | null>(null);
    const [activeMenuId, setActiveMenuId] = useState<string | null>(null);
    const [isPanelOpen, setIsPanelOpen] = useState(false);
    const [isAddDriverModalOpen, setIsAddDriverModalOpen] = useState(false);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const menuRef = useRef<HTMLDivElement>(null);

    // Close menu when clicking outside
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
                setActiveMenuId(null);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const fetchDrivers = async () => {
        try {
            setLoading(true);
            const data = await getAllDrivers();
            setDriversData(data);
            setError(null);
        } catch (err: any) {
            console.error('Failed to fetch drivers:', err);
            setError('Failed to load drivers. Check backend connection.');
            showToast('Connection Error', 'Unable to fetch drivers from backend', 'error');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDrivers();
    }, [showToast]);

    const handleDriverCreated = () => {
        fetchDrivers();
        showToast('Success', 'New driver added successfully', 'success');
    };

    const filteredDrivers = useMemo(() => {
        return driversData.filter(driver => {
            const matchesSearch = 
                driver.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                driver.plate?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                driver.loc?.toLowerCase().includes(searchTerm.toLowerCase());
            
            const matchesStatus = filterStatus ? driver.status === filterStatus : true;

            return matchesSearch && matchesStatus;
        });
    }, [searchTerm, filterStatus, driversData]);

    const handleActionClick = (driver: any) => {
        setSelectedDriver(driver);
        setIsPanelOpen(true);
    };

    const toggleMenu = (e: React.MouseEvent, driverId: string) => {
        e.stopPropagation();
        setActiveMenuId(activeMenuId === driverId ? null : driverId);
    };

    const handleEditDriver = (e: React.MouseEvent, driver: any) => {
        e.stopPropagation();
        setEditingDriver(driver);
        setIsAddDriverModalOpen(true);
        setActiveMenuId(null);
    };

    const handleDeleteDriver = async (e: React.MouseEvent, driverId: string) => {
        e.stopPropagation();
        if (window.confirm('Are you sure you want to delete this driver?')) {
            try {
                await deleteDriver(driverId);
                showToast('Success', 'Driver deleted successfully', 'success');
                fetchDrivers();
            } catch (err) {
                console.error('Failed to delete driver:', err);
                showToast('Error', 'Failed to delete driver', 'error');
            }
        }
        setActiveMenuId(null);
    };

    const handleModalClose = () => {
        setIsAddDriverModalOpen(false);
        setEditingDriver(null);
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

    return (
    <>
    <div className="space-y-6">
       <div className="flex justify-between items-end">
           <div>
               <h2 className="text-2xl font-bold text-white">Driver Directory & Performance</h2>
               <p className="text-eco-text-secondary text-sm mt-1">Manage and monitor driver performance</p>
           </div>
           <button 
                onClick={() => setIsAddDriverModalOpen(true)}
                className="bg-eco-brand-orange hover:bg-eco-brand-orange-hover text-white px-4 py-2 rounded-lg text-sm font-semibold shadow-neon-orange transition-all active:scale-95"
            >
               + Add Driver
           </button>
       </div>

       {/* Filters */}
       <div className="flex flex-col md:flex-row gap-4 bg-eco-card p-4 rounded-xl border border-eco-card-border">
           <div className="relative flex-1">
               <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
               <input 
                   type="text" 
                   value={searchTerm}
                   onChange={(e) => setSearchTerm(e.target.value)}
                   placeholder="Search drivers by name, vehicle, or location..." 
                   className="w-full bg-eco-secondary border border-eco-card-border rounded-lg pl-10 pr-4 py-2 text-sm text-white focus:outline-none focus:border-eco-brand-orange transition-colors placeholder:text-gray-600"
               />
           </div>
           <button 
                onClick={() => setFilterStatus(filterStatus === 'On Duty' ? null : 'On Duty')}
                className={`flex items-center px-4 py-2 border rounded-lg text-sm transition-colors ${filterStatus === 'On Duty' ? 'bg-eco-brand-orange text-white border-eco-brand-orange' : 'bg-eco-secondary border-eco-card-border text-eco-text-secondary hover:text-white hover:border-gray-500'}`}
            >
               <Filter className="w-4 h-4 mr-2" /> On Duty
           </button>
           <button 
                onClick={() => setFilterStatus(filterStatus === 'In Transit' ? null : 'In Transit')}
                className={`flex items-center px-4 py-2 border rounded-lg text-sm transition-colors ${filterStatus === 'In Transit' ? 'bg-eco-brand-orange text-white border-eco-brand-orange' : 'bg-eco-secondary border-eco-card-border text-eco-text-secondary hover:text-white hover:border-gray-500'}`}
            >
               <Truck className="w-4 h-4 mr-2" /> In Transit
           </button>
           <button 
                onClick={() => showToast('Location Filter', 'Filter by region functionality coming soon', 'info')}
                className="flex items-center px-4 py-2 bg-eco-secondary border border-eco-card-border rounded-lg text-eco-text-secondary text-sm hover:text-white hover:border-gray-500 transition-colors"
            >
               <MapPin className="w-4 h-4 mr-2" /> Location
           </button>
       </div>

       {/* Rows */}
       <div className="bg-eco-card rounded-xl border border-eco-card-border">
            <div className="grid grid-cols-12 px-6 py-3 text-xs font-medium text-eco-text-secondary uppercase tracking-wider border-b border-eco-card-border bg-eco-secondary/50">
                <div className="col-span-3">Driver</div>
                <div className="col-span-2">Phone</div>
                <div className="col-span-2">Vehicle</div>
                <div className="col-span-2">Current Location</div>
                <div className="col-span-1 text-center">Status</div>
                <div className="col-span-1 text-center">Rating</div>
                <div className="col-span-1 text-center">Actions</div>
            </div>

            <div className="divide-y divide-eco-card-border">
                {filteredDrivers.length > 0 ? filteredDrivers.map((driver) => (
                    <div key={driver.id} className="grid grid-cols-12 items-center bg-eco-card px-6 py-4 hover:bg-eco-secondary/30 transition-colors group">
                        <div className="col-span-3 flex items-center space-x-3">
                            <div className={`w-10 h-10 rounded-full ${driver.color} text-white flex items-center justify-center font-bold text-sm shadow-lg`}>
                                {driver.avatar}
                            </div>
                            <div>
                                <div className="font-medium text-white">{driver.name}</div>
                            </div>
                        </div>
                        
                        <div className="col-span-2 flex items-center text-eco-text-secondary text-sm">
                            <Phone className="w-3 h-3 mr-2 text-gray-500" /> {driver.phone}
                        </div>
                        
                        <div className="col-span-2">
                            <div className="text-white font-mono text-sm">{driver.plate}</div>
                            <div className="text-xs text-eco-text-secondary">{driver.vehicle}</div>
                        </div>
                        
                        <div className="col-span-2 text-eco-text-secondary text-sm flex items-center">
                            <MapPin className="w-3 h-3 mr-2 text-gray-500" /> {driver.loc}
                        </div>
                        
                        <div className="col-span-1 flex justify-center">
                            <span className={`px-3 py-1 rounded-full text-xs font-medium border ${
                                driver.status === 'On Duty' ? 'bg-eco-success/10 text-eco-success border-eco-success/20' :
                                driver.status === 'In Transit' ? 'bg-eco-info/10 text-eco-info border-eco-info/20' :
                                'bg-gray-700/50 text-gray-400 border-gray-600'
                            }`}>
                                {driver.status}
                            </span>
                        </div>
                        
                        <div className="col-span-1 flex items-center justify-center text-yellow-400 font-bold text-sm">
                            <Star className="w-4 h-4 mr-1 fill-current" /> {driver.rating}
                        </div>
                        
                        <div className="col-span-1 flex justify-center relative">
                            <button 
                                onClick={(e) => toggleMenu(e, driver.id)}
                                className="p-2 hover:bg-white/10 rounded-lg text-gray-400 hover:text-white transition-colors"
                            >
                                <MoreHorizontal className="w-4 h-4" />
                            </button>
                            
                            {activeMenuId === driver.id && (
                                <div 
                                    className="absolute right-0 top-full mt-1 w-48 bg-gray-900 border border-eco-card-border rounded-lg shadow-xl z-[100] overflow-hidden"
                                >
                                    <button 
                                        onClick={() => handleActionClick(driver)}
                                        className="w-full text-left px-4 py-3 text-sm text-gray-300 hover:bg-eco-secondary hover:text-white flex items-center transition-colors"
                                    >
                                        <Eye className="w-4 h-4 mr-2 text-eco-info" /> View Details
                                    </button>
                                    <button 
                                        onClick={(e) => handleEditDriver(e, driver)}
                                        className="w-full text-left px-4 py-3 text-sm text-gray-300 hover:bg-eco-secondary hover:text-white flex items-center transition-colors border-t border-eco-card-border"
                                    >
                                        <Edit className="w-4 h-4 mr-2 text-eco-brand-orange" /> Edit Driver
                                    </button>
                                    <button 
                                        onClick={(e) => handleDeleteDriver(e, driver.id)}
                                        className="w-full text-left px-4 py-3 text-sm text-gray-300 hover:bg-eco-secondary hover:text-white flex items-center transition-colors border-t border-eco-card-border"
                                    >
                                        <Trash className="w-4 h-4 mr-2 text-red-500" /> Delete Driver
                                    </button>
                                </div>
                            )}
                        </div>
                    </div>
                )) : (
                    <div className="p-8 text-center text-gray-400">
                        No drivers found matching your search.
                    </div>
                )}
            </div>
       </div>
    </div>
    
    {/* Driver Detail Panel */}
    <DriverDetailPanel 
        driver={selectedDriver}
        isOpen={isPanelOpen}
        onClose={() => setIsPanelOpen(false)}
    />
    
    <AddDriverModal 
        isOpen={isAddDriverModalOpen}
        onClose={handleModalClose}
        onSuccess={handleDriverCreated}
        createDriver={createDriver}
        updateDriver={updateDriver}
        initialData={editingDriver}
    />
    </>
  );
}

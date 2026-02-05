import { Leaf, TrendingDown, Award, Target, Zap, Cpu, Network } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar } from 'recharts';

const emissionTrend = [
  { month: 'Jan', value: 45 }, { month: 'Feb', value: 42 },
  { month: 'Mar', value: 38 }, { month: 'Apr', value: 35 },
  { month: 'May', value: 32 }, { month: 'Jun', value: 28 },
];

const efficiencyData = [
  { route: 'Mumbai-Delhi', value: 85 },
  { route: 'Ahmd-Mumbai', value: 92 },
  { route: 'Bang-Chennai', value: 78 },
  { route: 'Delhi-Kolkata', value: 88 },
  { route: 'Pune-Hyd', value: 80 },
];

const esgData = [
  { subject: 'Fuel Efficiency', A: 120, fullMark: 150 },
  { subject: 'Route Opti', A: 98, fullMark: 150 },
  { subject: 'Load Capa', A: 86, fullMark: 150 },
  { subject: 'Idle Time', A: 99, fullMark: 150 },
  { subject: 'Maintenance', A: 85, fullMark: 150 },
  { subject: 'Driver Training', A: 65, fullMark: 150 },
];

const initiatives = [
    { title: 'Electric Fleet Integration', desc: '15% of fleet transitioning to electric vehicles', progress: 65, impact: '3.2 Tons', status: 'In Progress', icon: Zap },
    { title: 'Route Optimization AI', desc: 'AI-powered route planning reducing fuel consumption', progress: 85, impact: '5.8 Tons', status: 'Active', icon: Cpu },
    { title: 'Virtual Hub Network', desc: 'Collaborative logistics reducing empty miles', progress: 72, impact: '4.1 Tons', status: 'In Progress', icon: Network },
];

export function CarbonTracking() {
  return (
    <div className="space-y-6">
       <div className="flex items-center text-sm text-eco-text-secondary mb-2">
           Dashboard <span className="mx-2">&gt;</span> <span className="text-white font-semibold">Carbon Tracking</span>
       </div>

       {/* Stats Row */}
       <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
           <CarbonStat title="Carbon Saved (MTD)" value="12.4 Tons" trend="-15.2%" trendDown icon={Leaf} color="text-eco-emerald-400" bg="bg-eco-emerald-500/10" />
           <CarbonStat title="Emission Reduction" value="23.6%" trend="+5.3%" icon={TrendingDown} color="text-blue-400" bg="bg-blue-500/10" />
           <CarbonStat title="ESG Score" value="87/100" trend="+3.2" icon={Award} color="text-purple-400" bg="bg-purple-500/10" />
           <CarbonStat title="Green Miles" value="45,678 km" trend="+12.1%" icon={Target} color="text-eco-brand-orange" bg="bg-eco-brand-orange/10" />
       </div>

       {/* Charts Row */}
       <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Emission Trend */}
            <div className="bg-eco-card rounded-xl border border-eco-card-border p-6 h-[350px]">
                <h3 className="text-white font-semibold mb-6">Carbon Emissions Trend</h3>
                <ResponsiveContainer width="100%" height="80%">
                    <AreaChart data={emissionTrend}>
                        <defs>
                            <linearGradient id="colorEmission" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#8B5CF6" stopOpacity={0.3}/>
                                <stop offset="95%" stopColor="#8B5CF6" stopOpacity={0}/>
                            </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" stroke="#2A3142" vertical={false} />
                        <XAxis dataKey="month" stroke="#8B92A8" tickLine={false} axisLine={false} dy={10} />
                        <YAxis stroke="#8B92A8" tickLine={false} axisLine={false} dx={-10} />
                        <Tooltip contentStyle={{ backgroundColor: '#151B28', borderColor: '#2A3142', color: '#fff' }} />
                        <Area type="monotone" dataKey="value" stroke="#8B5CF6" strokeWidth={3} fillOpacity={1} fill="url(#colorEmission)" />
                    </AreaChart>
                </ResponsiveContainer>
            </div>

            {/* Route Efficiency */}
            <div className="bg-eco-card rounded-xl border border-eco-card-border p-6 h-[350px]">
                <h3 className="text-white font-semibold mb-6">Route Carbon Efficiency</h3>
                <ResponsiveContainer width="100%" height="80%">
                    <BarChart data={efficiencyData}>
                         <CartesianGrid strokeDasharray="3 3" stroke="#2A3142" vertical={false} />
                         <XAxis dataKey="route" stroke="#8B92A8" tickLine={false} axisLine={false} dy={10} fontSize={10} />
                         <YAxis stroke="#8B92A8" tickLine={false} axisLine={false} dx={-10} />
                         <Tooltip contentStyle={{ backgroundColor: '#151B28', borderColor: '#2A3142', color: '#fff' }} cursor={{fill: 'transparent'}} />
                         <Bar dataKey="value" fill="#10B981" radius={[4, 4, 0, 0]} barSize={40} />
                    </BarChart>
                </ResponsiveContainer>
            </div>
       </div>

       {/* Bottom Row: ESG & Initiatives */}
       <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* ESG Radar */}
            <div className="lg:col-span-1 bg-eco-card rounded-xl border border-eco-card-border p-6 h-[400px]">
                <h3 className="text-white font-semibold mb-2">ESG Performance</h3>
                <ResponsiveContainer width="100%" height="100%">
                    <RadarChart cx="50%" cy="50%" outerRadius="70%" data={esgData}>
                        <PolarGrid stroke="#2A3142" />
                        <PolarAngleAxis dataKey="subject" tick={{ fill: '#8B92A8', fontSize: 10 }} />
                        <PolarRadiusAxis angle={30} domain={[0, 150]} tick={false} axisLine={false} />
                        <Radar name="ESG" dataKey="A" stroke="#FF6B35" fill="#FF6B35" fillOpacity={0.3} />
                        <Tooltip contentStyle={{ backgroundColor: '#151B28', borderColor: '#2A3142', color: '#fff' }} />
                    </RadarChart>
                </ResponsiveContainer>
            </div>

            {/* Initiatives List */}
            <div className="lg:col-span-2 bg-eco-card rounded-xl border border-eco-card-border p-6 space-y-6 h-[400px] overflow-y-auto custom-scrollbar">
                 <h3 className="text-white font-semibold mb-4">Sustainability Initiatives</h3>
                 
                 {initiatives.map((item, idx) => (
                     <div key={idx} className="bg-eco-secondary/50 p-5 rounded-xl border border-eco-card-border relative group hover:border-eco-brand-orange/30 transition-all">
                        <div className="flex justify-between items-start mb-2">
                            <div>
                                <h4 className="text-white font-medium text-lg">{item.title}</h4>
                                <p className="text-eco-text-secondary text-sm mt-1">{item.desc}</p>
                            </div>
                            <span className={`px-3 py-1 text-xs font-semibold rounded ${
                                item.status === 'Active' ? 'bg-eco-success/10 text-eco-success border border-eco-success/20' : 'bg-eco-brand-orange/10 text-eco-brand-orange border border-eco-brand-orange/20'
                            }`}>
                                {item.status}
                            </span>
                        </div>
                        
                        <div className="mt-4">
                            <div className="flex justify-between text-xs mb-2">
                                <span className="text-gray-400">Progress</span>
                                <span className="text-white font-bold">{item.progress}%</span>
                            </div>
                            <div className="h-2 w-full bg-gray-700/30 rounded-full overflow-hidden">
                                <div className="h-full bg-eco-success rounded-full transition-all duration-1000 ease-out" style={{width: `${item.progress}%`}}></div>
                            </div>
                        </div>

                        <div className="mt-4 flex items-center text-xs text-eco-success font-medium">
                            <Leaf className="w-4 h-4 mr-2" />
                            Impact: <span className="text-white ml-1">{item.impact} CO₂ saved/month</span>
                        </div>
                     </div>
                 ))}
            </div>
       </div>
    </div>
  );
}

function CarbonStat({ title, value, trend, trendDown, icon: Icon, color, bg }: any) {
    return (
        <div className="bg-eco-card rounded-xl p-6 border border-eco-card-border flex items-start justify-between shadow-sm hover:shadow-lg transition-shadow">
            <div>
                <div className="text-eco-text-secondary text-sm font-medium mb-1">{title}</div>
                <div className="text-2xl font-bold text-white mb-2">{value}</div>
                <div className={`text-xs font-semibold ${trendDown ? 'text-eco-success' : 'text-eco-success'}`}>
                    {trend}
                </div>
            </div>
            <div className={`p-3 rounded-lg ${bg}`}>
                <Icon className={`w-6 h-6 ${color}`} />
            </div>
        </div>
    )
}

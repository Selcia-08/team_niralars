import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';

const volumeData = [
  { name: 'Jan', value: 280, revenue: 120000 }, { name: 'Feb', value: 300, revenue: 150000 },
  { name: 'Mar', value: 320, revenue: 180000 }, { name: 'Apr', value: 310, revenue: 170000 },
  { name: 'May', value: 350, revenue: 220000 }, { name: 'Jun', value: 380, revenue: 250000 },
];

const routeData = [
  { name: 'Mumbai-Delhi', value: 240 },
  { name: 'Ahmd-Mumbai', value: 180 },
  { name: 'Bang-Chennai', value: 160 },
  { name: 'Delhi-Kolkata', value: 140 },
  { name: 'Pune-Hyd', value: 120 },
];

const pieData = [
  { name: 'On Time', value: 78, color: '#10B981' },
  { name: 'Delayed', value: 15, color: '#3B82F6' },
  { name: 'In Transit', value: 7, color: '#EF4444' },
];

export function Analytics() {
  return (
    <div className="space-y-6">
      <div className="flex items-center text-sm text-eco-text-secondary mb-2">
           Dashboard <span className="mx-2">&gt;</span> <span className="text-white font-semibold">Analytics</span>
      </div>
      
      {/* Top KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <KpiCard title="Total Revenue" value="₹12.4M" change="+12.5%" />
          <KpiCard title="Active Shipments" value="1,234" change="+8.2%" />
          <KpiCard title="Fleet Utilization" value="87%" change="-2.1%" negative />
          <KpiCard title="Active Drivers" value="456" change="+5.3%" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Top Left: Revenue Trend (Area) */}
          <div className="bg-eco-card rounded-xl border border-eco-card-border p-6 h-[320px]">
              <h3 className="text-white font-semibold mb-4">Revenue Trend</h3>
              <ResponsiveContainer width="100%" height="80%">
                  <AreaChart data={volumeData}>
                      <defs>
                           <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                               <stop offset="5%" stopColor="#8B5CF6" stopOpacity={0.3}/>
                               <stop offset="95%" stopColor="#8B5CF6" stopOpacity={0}/>
                           </linearGradient>
                       </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="#2A3142" vertical={false} />
                      <XAxis dataKey="name" stroke="#8B92A8" tickLine={false} axisLine={false} dy={10} />
                      <YAxis stroke="#8B92A8" tickLine={false} axisLine={false} dx={-10} />
                      <Tooltip contentStyle={{ backgroundColor: '#151B28', borderColor: '#2A3142', color: '#fff' }} />
                      <Area type="monotone" dataKey="revenue" stroke="#8B5CF6" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
                  </AreaChart>
              </ResponsiveContainer>
          </div>

          {/* Top Right: Top Routes (Bar) */}
          <div className="bg-eco-card rounded-xl border border-eco-card-border p-6 h-[320px]">
              <h3 className="text-white font-semibold mb-4">Top Routes</h3>
              <ResponsiveContainer width="100%" height="80%">
                  <BarChart layout="vertical" data={routeData}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#2A3142" horizontal={false} />
                      <XAxis type="number" stroke="#8B92A8" hide />
                      <YAxis dataKey="name" type="category" stroke="#8B92A8" tickLine={false} axisLine={false} width={100} fontSize={12} />
                      <Tooltip cursor={{fill: '#2A3142'}} contentStyle={{ backgroundColor: '#151B28', borderColor: '#2A3142', color: '#fff' }} />
                      <Bar dataKey="value" fill="#FF6B35" radius={[0, 4, 4, 0]} barSize={20} />
                  </BarChart>
              </ResponsiveContainer>
          </div>

          {/* Bottom Left: Delivery Performance (Donut) */}
          <div className="bg-eco-card rounded-xl border border-eco-card-border p-6 h-[320px] flex flex-col">
               <h3 className="text-white font-semibold mb-4">Delivery Performance</h3>
               <div className="flex-1 flex items-center justify-center relative">
                   <ResponsiveContainer width="100%" height="100%">
                       <PieChart>
                           <Pie data={pieData} innerRadius={60} outerRadius={80} paddingAngle={5} dataKey="value">
                               {pieData.map((entry, index) => (
                                   <Cell key={`cell-${index}`} fill={entry.color} stroke="none" />
                               ))}
                           </Pie>
                           <Tooltip contentStyle={{ backgroundColor: '#151B28', borderColor: '#2A3142', color: '#fff' }} />
                        </PieChart>
                   </ResponsiveContainer>
                   <div className="absolute inset-0 flex items-center justify-center pointer-events-none flex-col">
                       <span className="text-3xl font-bold text-white">78%</span>
                       <span className="text-xs text-eco-text-secondary">On Time</span>
                   </div>
               </div>
               <div className="flex justify-center gap-6 mt-2 text-xs">
                   {pieData.map(d => (
                       <div key={d.name} className="flex items-center text-eco-text-secondary">
                           <span className="w-2 h-2 rounded-full mr-2" style={{backgroundColor: d.color}}></span>
                           {d.name}
                       </div>
                   ))}
               </div>
          </div>

          {/* Bottom Right: Shipment Volume (Line) */}
           <div className="bg-eco-card rounded-xl border border-eco-card-border p-6 h-[320px]">
              <h3 className="text-white font-semibold mb-4">Shipment Volume</h3>
              <ResponsiveContainer width="100%" height="80%">
                  <LineChart data={volumeData}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#2A3142" vertical={false} />
                      <XAxis dataKey="name" stroke="#8B92A8" tickLine={false} axisLine={false} dy={10} />
                      <YAxis stroke="#8B92A8" tickLine={false} axisLine={false} dx={-10} />
                      <Tooltip contentStyle={{ backgroundColor: '#151B28', borderColor: '#2A3142', color: '#fff' }} />
                      <Line type="monotone" dataKey="value" stroke="#3B82F6" strokeWidth={3} dot={{r:4, fill:'#3B82F6'}} />
                  </LineChart>
              </ResponsiveContainer>
           </div>
      </div>
    </div>
  );
}

function KpiCard({ title, value, change, negative }: any) {
    return (
        <div className="bg-eco-card rounded-xl p-6 border border-eco-card-border shadow-sm">
            <div className="text-eco-text-secondary text-sm font-medium mb-2">{title}</div>
            <div className="flex items-baseline justify-between">
                <div className="text-2xl font-bold text-white">{value}</div>
                <div className={`text-xs font-semibold px-2 py-1 rounded-full ${negative ? 'bg-eco-brand-orange/10 text-eco-brand-orange' : 'bg-eco-success/10 text-eco-success'}`}>
                    {change}
                </div>
            </div>
        </div>
    )
}

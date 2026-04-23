import { useEffect } from 'react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import AppShell from './components/layout/AppShell';
import Dashboard from './routes/Dashboard';
import ItemList from './routes/ItemList';
import ItemForm from './routes/ItemForm';
import ItemDetail from './routes/ItemDetail';
import Categories from './routes/Categories';
import Locations from './routes/Locations';
import MedicineBox from './routes/MedicineBox';
import MedicineForm from './routes/MedicineForm';
import Statistics from './routes/Statistics';
import Settings from './routes/Settings';
import Logs from './routes/Logs';
import { startMedicationReminder } from './services/medicationReminder';
import { initLogger, logInfo } from './utils/logger';

export default function App() {
  useEffect(() => {
    initLogger();
    logInfo('应用启动', 'App');
    const cleanup = startMedicationReminder();
    return () => {
      logInfo('应用关闭', 'App');
      cleanup();
    };
  }, []);



  return (
    <MemoryRouter>
      <Routes>
        <Route element={<AppShell />}>
          <Route path="/" element={<Dashboard />} />
          <Route path="/items" element={<ItemList />} />
          <Route path="/items/new" element={<ItemForm />} />
          <Route path="/items/:id" element={<ItemDetail />} />
          <Route path="/items/:id/edit" element={<ItemForm />} />
          <Route path="/categories" element={<Categories />} />
          <Route path="/locations" element={<Locations />} />
          <Route path="/medicine" element={<MedicineBox />} />
          <Route path="/medicine/new" element={<MedicineForm />} />
          <Route path="/medicine/:id/edit" element={<MedicineForm />} />
          <Route path="/statistics" element={<Statistics />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/logs" element={<Logs />} />
        </Route>
      </Routes>
    </MemoryRouter>
  );
}

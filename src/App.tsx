import { useEffect } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
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

  // Prevent WebView swipe gesture navigation (completely disabled)
  useEffect(() => {
    let touchStartX = 0;
    let touchStartY = 0;
    let isHorizontalSwipe = false;

    const handleTouchStart = (e: TouchEvent) => {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
      isHorizontalSwipe = false;
    };

    const handleTouchMove = (e: TouchEvent) => {
      if (e.touches.length !== 1) return;

      const currentX = e.touches[0].clientX;
      const currentY = e.touches[0].clientY;
      const deltaX = currentX - touchStartX;
      const deltaY = Math.abs(currentY - touchStartY);

      // Detect horizontal swipe (anywhere on screen, not just edges)
      if (!isHorizontalSwipe && Math.abs(deltaX) > 15 && Math.abs(deltaX) > deltaY * 1.5) {
        isHorizontalSwipe = true;
      }

      // Block horizontal swipes completely
      if (isHorizontalSwipe) {
        e.preventDefault();
      }
    };

    // Capture phase to intercept before WebView handles it
    document.addEventListener('touchstart', handleTouchStart, { passive: true, capture: true });
    document.addEventListener('touchmove', handleTouchMove, { passive: false, capture: true });

    return () => {
      document.removeEventListener('touchstart', handleTouchStart, { capture: true });
      document.removeEventListener('touchmove', handleTouchMove, { capture: true });
    };
  }, []);

  return (
    <BrowserRouter>
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
    </BrowserRouter>
  );
}

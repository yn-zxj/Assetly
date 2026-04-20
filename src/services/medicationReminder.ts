import { isPermissionGranted, requestPermission, sendNotification, registerActionTypes } from '@tauri-apps/plugin-notification';
import { getAllMedicines } from './medicineService';
import { logInfo, logWarn, logError } from '../utils/logger';
import type { MedicineWithItem } from '../types/medicine';

const LAST_CHECK_KEY = 'medication_reminder_last_check';

/**
 * Check if a medicine should remind now based on frequency settings
 */
function shouldRemindNow(medicine: MedicineWithItem, now: Date): boolean {
  if (!medicine.is_taking) return false;

  // Check duration expiry using date range
  const today = now.toISOString().slice(0, 10);
  if (medicine.duration_start && today < medicine.duration_start) return false;
  if (medicine.duration_end && today > medicine.duration_end) return false;

  // Check frequency
  const { frequency_type, frequency_days, week_days } = medicine;
  const currentDay = now.getDay(); // 0=Sunday, 1=Monday...

  if (frequency_type === 'daily') {
    // Remind every day
  } else if (frequency_type === 'every_n_days') {
    const daysSinceStart = Math.floor((now.getTime() - new Date(medicine.duration_start || medicine.created_at).getTime()) / (1000 * 60 * 60 * 24));
    if (daysSinceStart % frequency_days !== 0) return false;
  } else if (frequency_type === 'weekly') {
    const allowedDays = week_days.split(',').map(Number);
    if (!allowedDays.includes(currentDay)) return false;
  }

  // Check time slots
  const timeSlots = medicine.time_slots.split(',').filter(Boolean);
  if (timeSlots.length === 0) return false;

  const currentHour = now.getHours();
  const currentMinute = now.getMinutes();

  for (const slot of timeSlots) {
    const [slotHour, slotMinute] = slot.split(':').map(Number);
    if (slotHour === currentHour && slotMinute === currentMinute) {
      return true;
    }
  }

  return false;
}

/**
 * Check all medicines and send notifications for those due
 */
export async function checkAndNotify() {
  try {
    // Check permission
    let permission = await isPermissionGranted();
    logInfo(`通知权限状态: ${permission}`, 'MedicationReminder');
    if (!permission) {
      const result = await requestPermission();
      permission = result === 'granted';
      logInfo(`请求通知权限结果: ${result}`, 'MedicationReminder');
    }
    if (!permission) {
      logWarn('通知权限未授予，跳过提醒检查', 'MedicationReminder');
      return;
    }

    const now = new Date();
    const lastCheckStr = localStorage.getItem(LAST_CHECK_KEY);
    const lastCheck = lastCheckStr ? new Date(lastCheckStr) : null;

    // Only check if it's been at least 50 seconds since last check (avoid duplicate notifications within the same minute)
    if (lastCheck && now.getTime() - lastCheck.getTime() < 50000) return;

    const medicines = await getAllMedicines();
    logInfo(`检查用药提醒: ${medicines.length} 个药品, 当前时间 ${now.toLocaleTimeString()}`, 'MedicationReminder');
    const reminded: string[] = [];

    for (const med of medicines) {
      if (shouldRemindNow(med, now)) {
        logInfo(`触发用药提醒: ${med.name} (${med.time_slots})`, 'MedicationReminder');
        await sendNotification({
          title: '用药提醒',
          body: `${med.name} - 该吃药了！`,
        });
        reminded.push(med.id);
      }
    }

    if (reminded.length > 0) {
      localStorage.setItem(LAST_CHECK_KEY, now.toISOString());
      logInfo(`发送了 ${reminded.length} 条用药提醒`, 'MedicationReminder');
    }
  } catch (error) {
    logError(`用药提醒检查失败: ${(error as Error).message}`, 'MedicationReminder');
  }
}

/**
 * Start periodic checking (call this on app startup)
 */
export function startMedicationReminder() {
  logInfo('启动用药提醒定时器 (每60秒检查一次)', 'MedicationReminder');

  // Register notification action types for Android
  try {
    registerActionTypes([
      {
        id: 'medication',
        actions: [
          { id: 'take', title: '已服用' },
          { id: 'snooze', title: '稍后提醒' },
        ],
      },
    ]);
    logInfo('通知 action types 注册成功', 'MedicationReminder');
  } catch (err) {
    logWarn(`通知 action types 注册失败: ${(err as Error).message}`, 'MedicationReminder');
  }

  // Check every minute
  const interval = setInterval(checkAndNotify, 60 * 1000);

  // Initial check
  checkAndNotify();

  return () => {
    logInfo('停止用药提醒定时器', 'MedicationReminder');
    clearInterval(interval);
  };
}

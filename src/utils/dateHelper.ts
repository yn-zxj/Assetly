import dayjs from 'dayjs';
import type { ExpiryStatus } from '../types/medicine';

export function formatDate(date: string): string {
  if (!date) return '';
  return dayjs(date).format('YYYY-MM-DD');
}

export function formatDateTime(date: string): string {
  if (!date) return '';
  return dayjs(date).format('YYYY-MM-DD HH:mm');
}

export function getNow(): string {
  return dayjs().format('YYYY-MM-DDTHH:mm:ss.SSS[Z]');
}

export function getToday(): string {
  return dayjs().format('YYYY-MM-DD');
}

export function daysUntil(date: string): number {
  return dayjs(date).diff(dayjs(), 'day');
}

export function daysSince(date: string): number {
  return dayjs().diff(dayjs(date), 'day');
}

export function getExpiryStatus(expiryDate: string): ExpiryStatus {
  const days = daysUntil(expiryDate);
  if (days < 0) return 'expired';
  if (days <= 30) return 'warning';
  return 'safe';
}

export function getExpiryLabel(expiryDate: string): string {
  const days = daysUntil(expiryDate);
  if (days < 0) return `已过期 ${Math.abs(days)} 天`;
  if (days === 0) return '今天过期';
  if (days <= 30) return `${days} 天后过期`;
  return `${days} 天`;
}

export function getMonthKey(date: string): string {
  return dayjs(date).format('YYYY-MM');
}

export function getMonthLabel(monthKey: string): string {
  return dayjs(monthKey + '-01').format('M月');
}

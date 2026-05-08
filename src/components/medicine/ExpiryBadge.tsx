import { getExpiryStatus, getExpiryLabel } from '../../utils/dateHelper';

interface ExpiryBadgeProps {
  expiryDate: string;
  className?: string;
}

export default function ExpiryBadge({ expiryDate, className = '' }: ExpiryBadgeProps) {
  const status = getExpiryStatus(expiryDate);
  const label = getExpiryLabel(expiryDate);

  const styles = {
    safe: 'bg-green-50 dark:bg-green-900/30 text-green-600 dark:text-green-400',
    warning: 'bg-yellow-50 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400',
    expired: 'bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400',
  };

  return (
    <span className={`inline-flex items-center text-xs px-2 py-0.5 rounded-full font-medium ${styles[status]} ${className}`}>
      {status === 'expired' && '!'} {label}
    </span>
  );
}

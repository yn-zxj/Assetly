import { getExpiryStatus, getExpiryLabel } from '../../utils/dateHelper';

interface ExpiryBadgeProps {
  expiryDate: string;
  className?: string;
}

export default function ExpiryBadge({ expiryDate, className = '' }: ExpiryBadgeProps) {
  const status = getExpiryStatus(expiryDate);
  const label = getExpiryLabel(expiryDate);

  const styles = {
    safe: 'bg-green-50 text-green-600',
    warning: 'bg-yellow-50 text-yellow-700',
    expired: 'bg-red-50 text-red-600',
  };

  return (
    <span className={`inline-flex items-center text-xs px-2 py-0.5 rounded-full font-medium ${styles[status]} ${className}`}>
      {status === 'expired' && '!'} {label}
    </span>
  );
}

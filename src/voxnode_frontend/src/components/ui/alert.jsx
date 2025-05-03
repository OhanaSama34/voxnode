import React, { useEffect } from 'react';
import {
  IconX,
  IconCheck,
  IconInfoCircle,
  IconAlertCircle,
} from '@tabler/icons-react';

const Alert = ({ type = 'info', message, onClose }) => {
  const alertConfig = {
    success: {
      class: 'alert-success',
      icon: <IconCheck className="size-6" />,
      title: 'Success!',
    },
    error: {
      class: 'alert-error',
      icon: <IconX className="size-6" />,
      title: 'Error!',
    },
    warning: {
      class: 'alert-warning',
      icon: <IconAlertCircle className="size-6" />,
      title: 'Warning!',
    },
    info: {
      class: 'alert-info',
      icon: <IconInfoCircle className="size-6" />,
      title: 'Info!',
    },
  };

  const {
    class: alertClass,
    icon,
    title,
  } = alertConfig[type] || alertConfig.info;

  useEffect(() => {
    if (onClose) {
      const timer = setTimeout(() => {
        onClose();
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [onClose]);

  return (
    <div
      className={`alert ${alertClass} shadow-lg max-w-md fixed top-18 right-4 z-50 animate-slide-in`}
    >
      <div className="flex items-center gap-2">
        {icon}
        <div>
          <h3 className="font-bold">{title}</h3>
          <p className="text-xs">{message}</p>
        </div>
      </div>
      {onClose && (
        <button className="btn btn-sm btn-ghost" onClick={onClose}>
          <IconX className="size-4" />
        </button>
      )}
    </div>
  );
};

export default Alert;

export enum UrgencyStatus {
  HIGH = 'HIGH',
  MEDIUM = 'MEDIUM',
  LOW = 'LOW',
}

export const urgenciesLabels: Record<UrgencyStatus, string> = {
  [UrgencyStatus.HIGH]: 'High',
  [UrgencyStatus.MEDIUM]: 'Medium',
  [UrgencyStatus.LOW]: 'Low',
};

export const urgenciesOptions = Object.keys(UrgencyStatus).map((key) => ({
  key: key as UrgencyStatus,
  label: urgenciesLabels[key as UrgencyStatus],
}));

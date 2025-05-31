export enum ConnectionStatus {
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  TRANSFERRED = 'TRANSFERRED', // Transferred to another professional
  ESCALATED = 'ESCALATED', // Escalated to admin
  BLOCKED = 'BLOCKED',
}

export const connectionStatusLabels: Record<ConnectionStatus, string> = {
  [ConnectionStatus.PENDING]: 'Pending',
  [ConnectionStatus.ACCEPTED]: 'Accepted',
  [ConnectionStatus.TRANSFERRED]: 'Transferred',
  [ConnectionStatus.ESCALATED]: 'Escalated',
  [ConnectionStatus.BLOCKED]: 'Blocked',
};

export const connectionStatusOptions = Object.keys(ConnectionStatus).map(
  (key) => ({
    key: key as ConnectionStatus,
    label: connectionStatusLabels[key as ConnectionStatus],
  })
);

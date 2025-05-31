export enum ProfessionalStatus {
  PENDING = 'PENDING', // Waiting for admin approval
  ACTIVE = 'ACTIVE', // Approved and currently available
  BLOCKED = 'BLOCKED', // Temporarily or permanently disabled by admin
  REJECTED = 'REJECTED', // Rejected by admin
  DEACTIVATED = 'DEACTIVATED', // Voluntarily or permanently deactivated
}

export const professionalStatusLabels: Record<ProfessionalStatus, string> = {
  [ProfessionalStatus.PENDING]: 'Pending',
  [ProfessionalStatus.ACTIVE]: 'Active',
  [ProfessionalStatus.BLOCKED]: 'Blocked',
  [ProfessionalStatus.REJECTED]: 'Rejected',
  [ProfessionalStatus.DEACTIVATED]: 'Deactivated',
};

export const professionalStatusOptions = Object.keys(ProfessionalStatus).map(
  (key) => ({
    key: key as ProfessionalStatus,
    label: professionalStatusLabels[key as ProfessionalStatus],
  })
);

export enum Specialization {
  MENTAL_HEALTH = 'MENTAL_HEALTH',
  COACHING = 'COACHING',
  FINANCIAL_WELLNESS = 'FINANCIAL_WELLNESS',
}

export const SpecializationLabels: Record<Specialization, string> = {
  [Specialization.MENTAL_HEALTH]: 'Mental Health',
  [Specialization.COACHING]: 'Coaching',
  [Specialization.FINANCIAL_WELLNESS]: 'Financial Wellness',
};

export const specializationOptions = Object.keys(Specialization).map((key) => ({
  key: key as Specialization,
  label: SpecializationLabels[key as Specialization],
}));

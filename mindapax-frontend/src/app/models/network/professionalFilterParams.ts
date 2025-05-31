export interface ProfessionalFilterParams {
  firstName?: string;
  lastName?: string;
  specialization?: string;
  experience?: number;
  availabilityDate?: string; // ISO date string
  status?: string;
  page?: number;
  size?: number;
  sort?: string;
}

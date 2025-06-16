import { ProfessionalStatus } from './enums/professionalStatus';
import { Specialization } from './enums/specialization';
import { User } from './user.model';

export interface Professional {
  id: number;
  bio: string;
  specialization: Specialization;
  certificates: string[];
  rating?: number;
  hourlyRate: number;
  experienceYears?: number;
  languages?: string[];
  availability?: string[];
  user: User;
  status: ProfessionalStatus;
  createdAt: Date;
  statusUpdatedAt?: Date;
  resumeUrl?: string;
  experience?: ProfessionalExperience[];
  certifications?: ProfessionalCertification[];
  rejectionNote?: string;
}

export interface ProfessionalExperience {
  title: string;
  company: string;
  startDate: Date;
  endDate?: Date;
  description: string;
}

export interface ProfessionalCertification {
  name: string;
  issuingOrganization?: string;
  issueDate?: Date;
  expiryDate?: Date;
  filePath?: string;
  description?: string;
}

import { Role } from '../enums/role';

export interface AuthRequest {
  email: string;
  password: string;
}

export interface RegisterRequest extends AuthRequest {
  firstName: string;
  lastName: string;
  password: string;
  agreeTerms: boolean;
  role: Role;
}

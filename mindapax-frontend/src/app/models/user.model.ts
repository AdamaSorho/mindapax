import { Role } from './enums/role';

export interface User {
  id: number;
  email: string;
  avatar?: string;
  firstName: string;
  lastName: string;
  phone: string;
  location: string;
  role: Role;
}

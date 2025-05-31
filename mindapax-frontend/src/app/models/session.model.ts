import { SessionMode, SessionStatus } from './enums/SessionFilter';

export interface Session {
  id: number;
  userId?: number;
  professionalId?: number;
  professionalName: string;
  professionalImage: string;
  specialization: string;
  date: Date;
  time?: string;
  startTime?: string;
  endTime?: string;
  mode: SessionMode;
  notes?: string;
  status?: SessionStatus;
}

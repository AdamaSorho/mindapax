import { SessionMode, SessionStatus } from './enums/SessionFilter';

export interface Session {
  id?: number; // Optional for new sessions, will be present when fetched
  userId: number; // REQUIRED when professional schedules for a user
  professionalId?: number; // Optional, backend derives from auth professional
  professionalName?: string; // Populated when fetching session details
  professionalSpecialization?: string; // Populated when fetching session details
  startTime: string; // ISO Date string, e.g., "2023-10-27T10:00:00Z"
  durationMinutes: number; // Duration in minutes
  mode: SessionMode;
  notes?: string;
  status?: SessionStatus; // Typically set by backend, or for filtering
}

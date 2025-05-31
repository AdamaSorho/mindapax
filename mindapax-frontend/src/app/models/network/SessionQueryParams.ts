import { SessionStatus, SessionTimeFilter } from '../enums/SessionFilter';

export interface SessionQueryParams {
  userId: number;
  filter: SessionTimeFilter;
  date?: string; // ISO string
  status?: SessionStatus;
  page?: number;
  size?: number;
  sort?: string; // e.g., 'date,asc'
}

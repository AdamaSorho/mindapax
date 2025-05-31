import { ConnectionStatus } from './enums/connectionStatus';
import { Specialization } from './enums/specialization';
import { UrgencyStatus } from './enums/urgencyStatus';
import { Professional } from './professional.model';
import { User } from './user.model';

export interface Connection {
  id: number;
  user: User;
  professional: Professional;
  status: ConnectionStatus;
  createdAt: Date;
  requestType?: Specialization;
  message?: string;
  urgency?: UrgencyStatus;
}

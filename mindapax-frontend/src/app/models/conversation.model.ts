import { Message } from './message.model';
import { Professional } from './professional.model';
import { User } from './user.model';

export interface Conversation {
  id: number;
  user: User;
  professional: Professional;
  lastMessage: Message;
  unreadCount?: number;
  isOnline?: boolean;
  createdAt?: Date;
}

export interface Message {
  id?: number;
  senderId: number;
  conversationId: number;
  content: string;
  timestamp: Date;
  isRead: boolean;
}

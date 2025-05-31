export interface Invoice {
  id: string;
  date: Date;
  service: string;
  professional: string;
  amount: number;
  status: 'paid' | 'pending' | 'overdue';
}

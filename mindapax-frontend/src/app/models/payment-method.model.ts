export interface PaymentMethod {
  id: string;
  type: 'credit' | 'paypal' | 'bank';
  lastFour?: string;
  expiryDate?: string;
  name: string;
  isDefault: boolean;
}

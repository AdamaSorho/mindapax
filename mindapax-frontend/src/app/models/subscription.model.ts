export interface Subscription {
  id: string;
  name: string;
  status: 'active' | 'canceled' | 'paused';
  price: number;
  billingCycle: 'monthly' | 'quarterly' | 'yearly';
  nextBillingDate: Date;
  features: string[];
}

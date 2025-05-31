import { Component, OnInit } from '@angular/core';
import { Subscription } from '../../models/subscription.model';
import { Invoice } from '../../models/invoice.model';
import { PaymentMethod } from '../../models/payment-method.model';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-billing',
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './billing.component.html',
  styleUrl: './billing.component.css',
})
export class BillingComponent implements OnInit {
  activeTab: 'overview' | 'invoices' | 'subscription' | 'payment-methods' =
    'overview';
  showAddPaymentModal = false;
  showCancelSubscriptionModal = false;

  currentPlan: Subscription = {
    id: 'sub_12345',
    name: 'Wellness Premium',
    status: 'active',
    price: 19.99,
    billingCycle: 'monthly',
    nextBillingDate: new Date('2025-04-22'),
    features: [
      'Unlimited mental wellness sessions',
      'Access to financial advisors',
      'Weekly fitness consultations',
      'Personalized wellness reports',
    ],
  };

  invoices: Invoice[] = [
    {
      id: 'INV-001',
      date: new Date('2025-03-15'),
      service: 'Wellness Premium Subscription',
      professional: 'N/A',
      amount: 19.99,
      status: 'paid',
    },
    {
      id: 'INV-002',
      date: new Date('2025-03-10'),
      service: 'One-time Fitness Consultation',
      professional: 'Sarah Johnson',
      amount: 45.0,
      status: 'paid',
    },
    {
      id: 'INV-003',
      date: new Date('2025-02-22'),
      service: 'Financial Planning Session',
      professional: 'Michael Chen',
      amount: 75.0,
      status: 'paid',
    },
    {
      id: 'INV-004',
      date: new Date('2025-02-15'),
      service: 'Wellness Premium Subscription',
      professional: 'N/A',
      amount: 19.99,
      status: 'paid',
    },
  ];

  paymentMethods: PaymentMethod[] = [
    {
      id: 'pm_1',
      type: 'credit',
      lastFour: '4242',
      expiryDate: '03/28',
      name: 'Visa ending in 4242',
      isDefault: true,
    },
    {
      id: 'pm_2',
      type: 'paypal',
      name: 'PayPal (adama@example.com)',
      isDefault: false,
    },
  ];

  plans: Subscription[] = [
    {
      id: 'basic',
      name: 'Wellness Basic',
      status: 'active',
      price: 9.99,
      billingCycle: 'monthly',
      nextBillingDate: new Date('2025-04-22'),
      features: [
        'Limited mental wellness sessions (3/month)',
        'Basic wellness reports',
        'Community forum access',
      ],
    },
    {
      id: 'premium',
      name: 'Wellness Premium',
      status: 'active',
      price: 19.99,
      billingCycle: 'monthly',
      nextBillingDate: new Date('2025-04-22'),
      features: [
        'Unlimited mental wellness sessions',
        'Access to financial advisors',
        'Weekly fitness consultations',
        'Personalized wellness reports',
      ],
    },
    {
      id: 'business',
      name: 'Wellness Business',
      status: 'active',
      price: 49.99,
      billingCycle: 'monthly',
      nextBillingDate: new Date('2025-04-22'),
      features: [
        'Everything in Premium',
        'Group sessions for teams',
        'Wellness program management',
        'Analytics and reporting',
        'Dedicated account manager',
      ],
    },
  ];

  constructor() {}

  ngOnInit(): void {}

  setActiveTab(
    tab: 'overview' | 'invoices' | 'subscription' | 'payment-methods'
  ): void {
    this.activeTab = tab;
  }

  togglePaymentModal(): void {
    this.showAddPaymentModal = !this.showAddPaymentModal;
  }

  toggleCancelSubscriptionModal(): void {
    this.showCancelSubscriptionModal = !this.showCancelSubscriptionModal;
  }

  setDefaultPaymentMethod(id: string): void {
    this.paymentMethods = this.paymentMethods.map((method) => ({
      ...method,
      isDefault: method.id === id,
    }));
  }

  removePaymentMethod(id: string): void {
    this.paymentMethods = this.paymentMethods.filter(
      (method) => method.id !== id
    );
  }

  downloadInvoice(id: string): void {
    console.log(`Downloading invoice ${id}`);
    // In a real application, this would trigger a download of the invoice
  }

  changePlan(planId: string): void {
    console.log(`Changing to plan: ${planId}`);
    // In a real application, this would update the subscription
  }
}

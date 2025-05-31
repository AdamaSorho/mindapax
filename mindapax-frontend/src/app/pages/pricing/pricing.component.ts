import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

@Component({
  selector: 'app-pricing',
  imports: [CommonModule],
  templateUrl: './pricing.component.html',
  styleUrl: './pricing.component.css',
})
export class PricingComponent {
  plans = [
    {
      name: 'Basic',
      price: '$29',
      period: 'monthly',
      features: [
        'Access to mental health professionals',
        '1 session per month',
        'Chat support',
        'Basic wellness resources',
        'Email support',
      ],
      popular: false,
      ctaText: 'Get started',
    },
    {
      name: 'Standard',
      price: '$79',
      period: 'monthly',
      features: [
        'Access to mental health professionals',
        '3 sessions per month',
        'Chat and video support',
        'Complete wellness resources',
        'Priority email & chat support',
        'Progress tracking',
      ],
      popular: true,
      ctaText: 'Get started',
    },
    {
      name: 'Premium',
      price: '$149',
      period: 'monthly',
      features: [
        'Access to all professionals',
        'Unlimited sessions',
        'Chat, video and messaging support',
        'Premium wellness resources',
        '24/7 priority support',
        'Advanced progress tracking',
        'Personalized wellness plan',
      ],
      popular: false,
      ctaText: 'Get started',
    },
  ];

  toggleBilling(event: Event) {
    // Implementation for toggle between monthly/yearly billing if needed
    console.log('Billing toggle changed', event);
  }
}

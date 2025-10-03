import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { SubscriptionsService, PlanDTO } from '../../services/subscriptions.service';
import { PaymentsService } from '../../services/payments.service';
import { Router } from '@angular/router';
import { CurrencyFormatPipe } from '../../pipes/currency-format.pipe';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-packages',
  standalone: true,
  imports: [CommonModule, CurrencyFormatPipe],
  templateUrl: './packages.component.html',
})
export class PackagesComponent {
  loading = true;
  error: string | null = null;
  plans: PlanDTO[] = [];
  // modal checkout state
  showModal = false;
  paymentId?: number;
  checkoutUrl = '';
  verifying = false;
  verifiedStatus: string | null = null;
  toastMsg: string | null = null;

  constructor(private subs: SubscriptionsService, private payments: PaymentsService, private router: Router, private toast: ToastService) { this.load(); }

  load() {
    this.loading = true; this.error = null;
    this.subs.listPlans().subscribe({
      next: (list) => { this.plans = list; this.loading = false; },
      error: () => {
        this.error = 'Failed to load packages'; this.loading = false;
        this.toast.error('Failed to load packages', 6000, [{ label: 'Retry' }]);
      }
    });
  }

  subscribe(plan: PlanDTO) {
    this.loading = true; this.error = null; this.verifiedStatus = null;
    this.subs.subscribe(plan.id).subscribe({
      next: (resp) => {
        this.loading = false;
        this.paymentId = resp.paymentId;
        this.checkoutUrl = resp.checkoutUrl;
        this.showModal = true;
      },
      error: () => {
        this.error = 'Failed to start checkout'; this.loading = false;
        this.toast.error('Could not start checkout', 7000, [{ label: 'Retry' }]);
      }
    });
  }

  verifyPayment() {
    if (!this.paymentId) return;
    this.verifying = true; this.verifiedStatus = null;
    this.payments.getPayment(this.paymentId).subscribe({
      next: (p) => {
        this.verifiedStatus = (p.status || '').toString();
        this.verifying = false;
        if (this.verifiedStatus.toUpperCase() === 'COMPLETED') {
          this.showModal = false;
          // Navigate to subscriptions and show toast there
          this.toast.success('Subscription activated successfully.');
          this.router.navigate(['/member/subscriptions']);
        } else if (this.verifiedStatus.toUpperCase() === 'FAILED') {
          this.toast.error('Payment failed', 7000, [
            ...(this.checkoutUrl ? [{ label: 'Open checkout', externalUrl: this.checkoutUrl }] : []),
          ]);
        } else {
          this.toast.info('Payment pending. You can verify again shortly.', 5000);
        }
      },
      error: () => {
        this.verifiedStatus = 'ERROR'; this.verifying = false;
        this.toast.error('Could not verify payment', 6000, [
          ...(this.checkoutUrl ? [{ label: 'Open checkout', externalUrl: this.checkoutUrl }] : []),
          { label: "I've paid" },
        ]);
      }
    });
  }

  featuresFor(p: PlanDTO): string[] {
    const sessions = p.sessionAllowance || 0;
    const common = [
      'AI Assistant with personalized context',
      'Goal recommendations and tracking',
      'Session scheduling',
      'Secure billing & subscriptions',
    ];
    const byName = (p.name || '').toLowerCase();
    if (byName.includes('premium')) {
      return [
        ...common,
        `${sessions} sessions per cycle`,
        'Priority booking',
        'Advanced progress insights',
      ];
    }
    if (byName.includes('standard')) {
      return [
        ...common,
        `${sessions} sessions per cycle`,
        'Priority booking',
      ];
    }
    // Basic or others
    return [
      ...common,
      `${sessions} sessions per cycle`,
    ];
  }
}

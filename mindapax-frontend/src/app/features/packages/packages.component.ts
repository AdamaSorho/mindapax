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
    if (plan.trial && plan.eligibleForTrial === false) {
      this.toast.info('You have already used your trial. Pick a plan to keep going.');
      return;
    }
    this.loading = true; this.error = null; this.verifiedStatus = null;
    this.subs.subscribe(plan.id).subscribe({
      next: (resp) => {
        this.loading = false;
        if (!resp.requiresPayment) {
          const days = plan.trialDurationDays ?? 7;
          this.showModal = false;
          this.paymentId = undefined;
          this.checkoutUrl = '';
          if (plan.trial) {
            this.toast.success(`Trial activated! Enjoy Mindapax for ${days} day${days === 1 ? '' : 's'}.`);
            plan.eligibleForTrial = false;
            this.router.navigate(['/member/dashboard']);
          } else {
            this.toast.success('Subscription activated successfully.');
            this.router.navigate(['/member/subscriptions']);
          }
          return;
        }
        const checkoutUrl = (resp.checkoutUrl ?? '').trim();
        if (!resp.paymentId || !checkoutUrl) {
          this.error = 'Checkout is currently unavailable. Please try again shortly.';
          this.toast.error(this.error!, 6000, [{ label: 'Retry' }]);
          return;
        }
        this.paymentId = resp.paymentId;
        this.checkoutUrl = checkoutUrl;
        this.showModal = true;
      },
      error: (err) => {
        const message = (err?.error?.message || 'Failed to start checkout').toString();
        this.error = message; this.loading = false;
        this.toast.error(message, 7000, [{ label: 'Retry' }]);
      }
    });
  }

  buttonLabel(plan: PlanDTO): string {
    if (plan.trial) {
      return plan.eligibleForTrial === false ? 'Trial used' : 'Start free trial';
    }
    return 'Subscribe';
  }

  disableSubscribe(plan: PlanDTO): boolean {
    if (this.loading) return true;
    if (plan.trial && plan.eligibleForTrial === false) return true;
    return false;
  }

  verifyPayment() {
    if (!this.paymentId) return;
    this.verifying = true; this.verifiedStatus = null;
    this.payments.getPayment(this.paymentId).subscribe({
      next: (p) => {
        this.verifiedStatus = (p.status || '').toString();
        this.verifying = false;
        const statusUpper = (this.verifiedStatus || '').toUpperCase();
        if (statusUpper === 'COMPLETED') {
          this.showModal = false;
          // Navigate to subscriptions and show toast there
          this.toast.success('Subscription activated successfully.');
          this.router.navigate(['/member/subscriptions']);
        } else if (statusUpper === 'FAILED') {
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

  private fallbackFeatures(p: PlanDTO): string[] {
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

  featuresFor(p: PlanDTO): string[] {
    const server = (p.features || []).map(f => (f || '').toString().trim()).filter(Boolean);
    if (server.length > 0) return server;
    return this.fallbackFeatures(p);
  }
}

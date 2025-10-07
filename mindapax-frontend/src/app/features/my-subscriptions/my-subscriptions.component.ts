import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { SubscriptionsService, SubscriptionDTO } from '../../services/subscriptions.service';
import { ToastService } from '../../services/toast.service';
import { CurrencyFormatPipe } from '../../pipes/currency-format.pipe';

@Component({
  selector: 'app-my-subscriptions',
  standalone: true,
  imports: [CommonModule, CurrencyFormatPipe],
  templateUrl: './my-subscriptions.component.html',
})
export class MySubscriptionsComponent {
  loading = true;
  error: string | null = null;
  subs: SubscriptionDTO[] = [];
  toastMsg: string | null = null;

  constructor(private api: SubscriptionsService, private toast: ToastService) { this.load(); }

  load() {
    this.loading = true; this.error = null;
    this.api.mySubscriptions().subscribe({
      next: (list) => { this.subs = list; this.loading = false; },
      error: () => { this.error = null; this.loading = false; this.toast.error('Failed to load subscriptions', 6000, [{ label: 'Retry' }]); },
    });
  }
}

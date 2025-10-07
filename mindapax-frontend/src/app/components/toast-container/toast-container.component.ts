import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { ToastService, ToastItem, ToastAction } from '../../services/toast.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-toast-container',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './toast-container.component.html',
})
export class ToastContainerComponent {
  toasts: ToastItem[] = [];
  constructor(public ts: ToastService, private router: Router) {
    this.ts.toasts$.subscribe(list => this.toasts = list);
  }
  css(t: ToastItem) {
    switch (t.type) {
      case 'success': return 'bg-green-50 text-green-800 border-green-200';
      case 'error': return 'bg-red-50 text-red-800 border-red-200';
      default: return 'bg-gray-800 text-white border-gray-700';
    }
  }
  run(a: ToastAction, id: number) {
    try {
      if (a.route) this.router.navigate([a.route]);
      else if (a.externalUrl) window.open(a.externalUrl, '_blank');
    } finally {
      this.ts.dismiss(id);
    }
  }
}

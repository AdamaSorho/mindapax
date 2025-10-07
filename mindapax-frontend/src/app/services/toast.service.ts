import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export type ToastType = 'success' | 'error' | 'info';
export interface ToastAction { label: string; route?: string; externalUrl?: string; }
export interface ToastItem { id: number; message: string; type: ToastType; timeout?: number; actions?: ToastAction[] }

@Injectable({ providedIn: 'root' })
export class ToastService {
  private _toasts$ = new BehaviorSubject<ToastItem[]>([]);
  public toasts$ = this._toasts$.asObservable();
  private _seq = 1;

  show(message: string, type: ToastType = 'info', timeout = 4000, actions?: ToastAction[]) {
    const id = this._seq++;
    const next = [...this._toasts$.value, { id, message, type, timeout, actions } as ToastItem];
    this._toasts$.next(next);
    if (timeout && timeout > 0) {
      setTimeout(() => this.dismiss(id), timeout);
    }
  }

  success(message: string, timeout = 4000, actions?: ToastAction[]) { this.show(message, 'success', timeout, actions); }
  error(message: string, timeout = 5000, actions?: ToastAction[]) { this.show(message, 'error', timeout, actions); }
  info(message: string, timeout = 4000, actions?: ToastAction[]) { this.show(message, 'info', timeout, actions); }

  dismiss(id: number) {
    this._toasts$.next(this._toasts$.value.filter(t => t.id !== id));
  }
}

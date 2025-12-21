import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface PlanDTO {
  id: number;
  name: string;
  price: number;
  currency: string;
  billingCycle: 'MONTHLY' | 'YEARLY';
  description?: string;
  active: boolean;
  sessionAllowance: number;
  features?: string[];
  trial: boolean;
  trialDurationDays?: number;
  eligibleForTrial?: boolean;
  requiresPayment: boolean;
}

export interface CheckoutResponse {
  paymentId?: number;
  checkoutUrl?: string;
  requiresPayment: boolean;
  subscriptionId: number;
  activeUntil?: string;
}

export interface SubscriptionDTO {
  id: number;
  planId: number;
  planName: string;
  planPrice: number;
  planCurrency: string;
  status: 'PENDING' | 'ACTIVE' | 'CANCELED' | 'EXPIRED';
  currentPeriodStart?: string;
  currentPeriodEnd?: string;
  remainingSessions?: number;
  lastPaymentId?: number;
}

@Injectable({ providedIn: 'root' })
export class SubscriptionsService {
  private readonly base = environment.apiUrl;
  constructor(private http: HttpClient) {}

  listPlans(): Observable<PlanDTO[]> {
    return this.http.get<PlanDTO[]>(`${this.base}/packages`);
  }

  subscribe(planId: number): Observable<CheckoutResponse> {
    return this.http.post<CheckoutResponse>(`${this.base}/packages/${planId}/subscribe`, {});
  }

  mySubscriptions(): Observable<SubscriptionDTO[]> {
    return this.http.get<SubscriptionDTO[]>(`${this.base}/packages/me`);
  }
}

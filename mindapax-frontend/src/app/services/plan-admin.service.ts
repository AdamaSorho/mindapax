import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface Plan {
  id?: number;
  name: string;
  price: number;
  currency: string;
  billingCycle: 'MONTHLY' | 'YEARLY';
  description?: string;
  active: boolean;
  sessionAllowance: number;
  features?: string[];
}

@Injectable({ providedIn: 'root' })
export class PlanAdminService {
  private readonly base = environment.apiUrl + '/admin/plans';
  constructor(private http: HttpClient) {}

  list(): Observable<Plan[]> { return this.http.get<Plan[]>(this.base); }
  create(p: Plan): Observable<Plan> { return this.http.post<Plan>(this.base, p); }
  update(id: number, p: Plan): Observable<Plan> { return this.http.put<Plan>(`${this.base}/${id}`, p); }
  delete(id: number): Observable<void> { return this.http.delete<void>(`${this.base}/${id}`); }
}

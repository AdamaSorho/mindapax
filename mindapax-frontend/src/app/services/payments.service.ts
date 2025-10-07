import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class PaymentsService {
  private readonly base = environment.apiUrl + '/payments';
  constructor(private http: HttpClient) {}
  getPayment(id: number): Observable<any> { return this.http.get<any>(`${this.base}/${id}`); }
}


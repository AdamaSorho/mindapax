import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';
import { HttpClient, HttpParams } from '@angular/common/http';
import { SessionQueryParams } from '../models/network/SessionQueryParams';
import { Observable } from 'rxjs';
import { Session } from '../models/session.model'; // Added import
import { SessionMode } from '../models/enums/SessionFilter'; // Added import

// Define the payload interface
export interface ScheduleSessionPayload {
  userId: number;
  startTime: string; // ISO 8601 format
  durationMinutes: number;
  mode: SessionMode;
  notes?: string;
}

@Injectable({
  providedIn: 'root',
})
export class SessionService {
  private readonly baseUrl = environment.apiUrl + '/sessions';

  constructor(private http: HttpClient) {}

  getSessions(params: SessionQueryParams): Observable<any> {
    let httpParams = new HttpParams()
      .set('userId', params.userId)
      .set('filter', params.filter);

    if (params.date) httpParams = httpParams.set('date', params.date);
    if (params.status) httpParams = httpParams.set('status', params.status);
    if (params.page != null) httpParams = httpParams.set('page', params.page);
    if (params.size != null) httpParams = httpParams.set('size', params.size);
    if (params.sort) httpParams = httpParams.set('sort', params.sort);

    return this.http.get(`${this.baseUrl}/by-user`, { params: httpParams });
  }

  scheduleSessionByProfessional(
    payload: ScheduleSessionPayload
  ): Observable<Session> {
    return this.http.post<Session>(
      `${this.baseUrl}/professional/schedule`,
      payload
    );
  }
}

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface MicroSession {
  id?: number;
  title: string;
  description: string;
  domain: string;
  outcomes: string[];
  minutes: number;
  steps: string[];
}

@Injectable({ providedIn: 'root' })
export class MicroSessionAdminService {
  private readonly base = environment.apiUrl + '/micro-sessions';

  constructor(private http: HttpClient) {}

  list(): Observable<MicroSession[]> {
    return this.http.get<MicroSession[]>(this.base);
  }

  create(session: MicroSession): Observable<MicroSession> {
    return this.http.post<MicroSession>(this.base, session);
  }

  update(id: number, session: MicroSession): Observable<MicroSession> {
    return this.http.put<MicroSession>(`${this.base}/${id}`, session);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.base}/${id}`);
  }
}

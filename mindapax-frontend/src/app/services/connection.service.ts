import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { Connection } from '../models/connection.model';
import { ConnectionStatus } from '../models/enums/connectionStatus';

@Injectable({
  providedIn: 'root',
})
export class ConnectionService {
  private readonly baseUrl = `${environment.apiUrl}/connections`;

  constructor(private http: HttpClient) {}

  connectWithProfessional(
    userId: number,
    proId: number
  ): Observable<Connection> {
    return this.http.post<Connection>(`${this.baseUrl}/${userId}`, {
      professionalId: proId,
    });
  }

  getConnections(
    ownerId: number,
    scope: 'user' | 'professional' = 'professional'
  ): Observable<Connection[]> {
    const path = scope === 'user' ? 'user' : 'professional';
    return this.http
      .get<Connection[]>(`${this.baseUrl}/${path}/${ownerId}`)
      .pipe(
        map((connections) =>
          connections.map((connection) => ({
            ...connection,
            createdAt: new Date(connection.createdAt),
          }))
        )
      );
  }

  updateConnection(
    connectionId: number,
    connectionStatus: ConnectionStatus
  ): Observable<Connection> {
    const httpParams = new HttpParams().set('status', connectionStatus);

    return this.http.put<Connection>(
      `${this.baseUrl}/${connectionId}/status`,
      null,
      {
        params: httpParams,
      }
    );
  }

  transferConnection(
    connectionId: number,
    professionalId: number,
    reason?: string,
    escalateToAdmin: boolean = false
  ): Observable<Connection> {
    const body: any = { professionalId };
    if (reason && reason.trim().length > 0) body.reason = reason.trim();
    if (escalateToAdmin) body.escalateToAdmin = true;
    return this.http.put<Connection>(
      `${this.baseUrl}/${connectionId}/transfer`,
      body
    );
  }
}

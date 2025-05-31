import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
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

  getConnections(userId: number): Observable<Connection[]> {
    return this.http.get<Connection[]>(
      `${this.baseUrl}/professional/${userId}`
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
}

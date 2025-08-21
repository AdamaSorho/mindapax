import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface ChatResponse {
  reply: string;
}

@Injectable({ providedIn: 'root' })
export class AiAssistantService {
  private baseUrl = `${environment.apiUrl}/assistant`;

  constructor(private http: HttpClient) {}

  sendMessage(message: string): Observable<ChatResponse> {
    return this.http.post<ChatResponse>(this.baseUrl, { message });
  }
}


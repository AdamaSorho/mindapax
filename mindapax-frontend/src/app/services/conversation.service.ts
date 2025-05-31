import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Conversation } from '../models/conversation.model';
import { PagedResponse } from '../models/network/pagedResponse';

@Injectable({
  providedIn: 'root',
})
export class ConversationService {
  private readonly BASE_URL = `${environment.apiUrl}/conversations`;

  constructor(private http: HttpClient) {}

  getConversations(
    userId: number,
    page: number,
    size: number
  ): Observable<PagedResponse<Conversation>> {
    return this.http.get<PagedResponse<Conversation>>(
      `${this.BASE_URL}/${userId}?page=${page}&size=${size}`
    );
  }

  startConversation(
    senderId: number,
    participantId: number
  ): Observable<Conversation> {
    return this.http.post<Conversation>(this.BASE_URL, {
      senderId,
      participantId,
    });
  }
}

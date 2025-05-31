import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, Subject, BehaviorSubject, throwError } from 'rxjs';
import { Client, IMessage, StompHeaders } from '@stomp/stompjs';
import { Message } from '../models/message.model';
import SockJS from 'sockjs-client';
import { environment } from '../../environments/environment';
import { PagedResponse } from '../models/network/pagedResponse';
import { catchError, switchMap, tap } from 'rxjs/operators';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root',
})
export class MessageService {
  private stompClient!: Client;
  private messageSubject = new Subject<Message>();
  private connectionStatusSubject = new BehaviorSubject<boolean>(false);
  private reconnectAttempts = 0;
  private readonly MAX_RECONNECT_ATTEMPTS = 5;

  private readonly BASE_URL = `${environment.apiUrl}/messages`;

  constructor(
    private http: HttpClient,
    private authService: AuthService // Inject your auth service
  ) {}

  // Get connection status as observable
  get connectionStatus$(): Observable<boolean> {
    return this.connectionStatusSubject.asObservable();
  }

  // 👉 Connect to WebSocket with token
  connectWebSocket(conversationId: number): void {
    // Get the current token
    const token = this.authService.getAccessToken();

    if (!token) {
      console.error('No authentication token available');
      return;
    }

    this.stompClient = new Client({
      webSocketFactory: () => new SockJS(environment.webSocketUrl),
      reconnectDelay: 5000,
      connectHeaders: {
        Authorization: `Bearer ${token}`,
      },
      onConnect: () => {
        console.log('WebSocket connection established');
        this.connectionStatusSubject.next(true);
        this.reconnectAttempts = 0;

        this.stompClient.subscribe(
          `/topic/messages/${conversationId}`,
          (msg: IMessage) => {
            const message: Message = JSON.parse(msg.body);
            this.messageSubject.next(message);
          },
          // Pass token in subscription headers as well if required by your backend
          { Authorization: `Bearer ${token}` } as StompHeaders
        );
      },
      onStompError: (frame) => {
        console.error('Broker reported error: ' + frame.headers['message']);
        console.error('Additional details: ' + frame.body);

        // Handle authentication errors (401 Unauthorized)
        if (
          frame.headers['message']?.includes('Unauthorized') ||
          frame.headers['message']?.includes('Invalid token')
        ) {
          this.handleTokenExpiration(conversationId);
        }
      },
      onWebSocketClose: (event) => {
        console.log('WebSocket connection closed', event);
        this.connectionStatusSubject.next(false);

        // Check if closure was due to authentication issues (code 1003 or 1008 often used for auth errors)
        if (event.code === 1003 || event.code === 1008) {
          this.handleTokenExpiration(conversationId);
        }
      },
    });

    this.stompClient.activate();
  }

  // 👉 Handle token expiration
  private handleTokenExpiration(conversationId: number): void {
    console.log('Token might be expired, attempting to refresh...');

    if (this.reconnectAttempts >= this.MAX_RECONNECT_ATTEMPTS) {
      console.error('Max reconnection attempts reached');
      this.authService.logoutAndRedirectToLogin(); // Force logout after too many failed attempts
      return;
    }

    this.reconnectAttempts++;

    // Disconnect current client
    if (this.stompClient && this.stompClient.active) {
      this.stompClient.deactivate();
    }

    // Refresh token and reconnect
    this.authService.refreshToken().subscribe({
      next: () => {
        console.log('Token refreshed successfully, reconnecting...');
        this.connectWebSocket(conversationId);
      },
      error: (error) => {
        console.error('Failed to refresh token', error);
        this.authService.logoutAndRedirectToLogin(); // Logout on token refresh failure
      },
    });
  }

  // 👉 Disconnect WebSocket
  disconnectWebSocket(): void {
    if (this.stompClient && this.stompClient.active) {
      this.stompClient.deactivate();
      this.connectionStatusSubject.next(false);
    }
  }

  // 👉 Listen to incoming messages
  onMessage(): Observable<Message> {
    return this.messageSubject.asObservable();
  }

  // 👉 Send real-time message with token
  sendMessage(message: Message): Observable<void> {
    if (!this.stompClient || !this.stompClient.connected) {
      return throwError(() => new Error('WebSocket not connected'));
    }

    // Get current token before sending
    const token = this.authService.getAccessToken();

    return new Observable<void>((observer) => {
      this.stompClient.publish({
        destination: '/app/chat',
        body: JSON.stringify(message),
        headers: { Authorization: `Bearer ${token}` },
      });
      observer.next();
      observer.complete();
    });
  }

  // 👉 Fetch message history between two users with token handling
  getMessageHistory(
    conversationId: number,
    page = 0,
    size = 20
  ): Observable<PagedResponse<Message>> {
    const params = new HttpParams()
      .set('conversationId', conversationId)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http
      .get<PagedResponse<Message>>(this.BASE_URL, { params })
      .pipe(
        catchError((error) => {
          // Handle 401 Unauthorized errors for HTTP requests
          if (error.status === 401) {
            // Try to refresh token and retry the request
            return this.authService
              .refreshToken()
              .pipe(
                switchMap(() =>
                  this.getMessageHistory(conversationId, page, size)
                )
              );
          }
          return throwError(() => error);
        })
      );
  }
}

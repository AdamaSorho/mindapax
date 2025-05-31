import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthRequest, RegisterRequest } from '../models/requests/auth.request';
import { User } from '../models/user.model';
import { Observable, tap } from 'rxjs';
import { Token } from '../models/token.model';
import { Router } from '@angular/router';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  apiUrl = environment.apiUrl + '/auth';
  constructor(private http: HttpClient, private router: Router) {}

  login(authRequest: AuthRequest): Observable<Token> {
    return this.http.post<Token>(this.apiUrl + '/login', authRequest).pipe(
      tap((response) => {
        this.storeTokens(
          response.accessToken,
          response.refreshToken,
          response.expiresIn
        );
      })
    );
  }

  refreshToken(): Observable<Token> {
    const refreshToken = localStorage.getItem('refreshToken');
    return this.http
      .post<Token>(`${this.apiUrl}/refresh-token`, { refreshToken })
      .pipe(
        tap((res: any) => {
          this.storeTokens(res.accessToken, res.refreshToken, res.expiresIn);
        })
      );
  }

  register(registerRequest: FormData): Observable<User> {
    for (const entry of registerRequest.entries()) {
      console.log(`key: ${entry[0]}, value: ${entry[1]}`);
    }
    return this.http.post<User>(this.apiUrl + '/register', registerRequest);
  }

  logout(): Observable<any> {
    const refreshToken = localStorage.getItem('refreshToken');
    return this.http.post<any>(`${this.apiUrl}/logout`, { refreshToken }).pipe(
      tap(() => {
        this.clearTokens();
      })
    );
  }

  // Get current authentication status
  get isAuthenticated(): boolean {
    return this.hasValidToken();
  }

  hasValidToken(): boolean {
    return !!this.getAccessToken() && !this.isTokenExpired();
  }

  logoutAndRedirectToLogin() {
    this.logout().subscribe(() => {
      this.router.navigate(['/auth/login']);
    });
  }

  private storeTokens(
    accessToken: string,
    refreshToken: string,
    expiresIn: number
  ): void {
    localStorage.setItem('accessToken', accessToken);
    localStorage.setItem('refreshToken', refreshToken);
    localStorage.setItem(
      'expiresAt',
      (Date.now() + expiresIn * 1000).toString()
    );
  }

  getDecodedAccessToken(): any {
    const token = this.getAccessToken();
    if (!token) return null;

    try {
      const payload = token.split('.')[1];
      const decodedPayload = atob(payload);
      return JSON.parse(decodedPayload);
    } catch (err) {
      console.error('Failed to decode token', err);
      return null;
    }
  }

  private clearTokens(): void {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('expiresAt');
  }

  getAccessToken(): string | null {
    return localStorage.getItem('accessToken');
  }

  isTokenExpired(): boolean {
    const expiresAt = parseInt(localStorage.getItem('expiresAt') || '0', 10);
    return Date.now() > expiresAt;
  }

  getUsername(): string | null {
    const decoded = this.getDecodedAccessToken();
    return decoded?.sub || null;
  }

  getFirstName(): string | null {
    const decoded = this.getDecodedAccessToken();
    return decoded?.firstName || null;
  }

  getLastName(): string | null {
    const decoded = this.getDecodedAccessToken();
    return decoded?.lastName || null;
  }

  getRoles(): string[] {
    const decoded = this.getDecodedAccessToken();
    return decoded?.roles || [];
  }

  getUserId(): number {
    const decoded = this.getDecodedAccessToken();
    return decoded?.id || null;
  }
}

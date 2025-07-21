import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http'; // Added HttpParams
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators'; // Added map operator
import { User } from '../models/user.model';
import { PagedResponse } from '../models/network/pagedResponse'; // Added PagedResponse
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class UserService {
  private readonly apiUrl = environment.apiUrl; // Base API URL

  constructor(private http: HttpClient) {}

  getProfessionalConnectedUsers(): Observable<User[]> {
    // Fetches users connected to the currently authenticated professional
    // The backend endpoint /api/v1/professionals/me/connected-users handles filtering.
    // It expects pagination parameters.
    const params = new HttpParams().set('page', '0').set('size', '50'); // Fetch up to 50 users by default, adjust as needed

    return this.http
      .get<PagedResponse<User>>(
        `${this.apiUrl}/professionals/me/connected-users`,
        { params }
      )
      .pipe(map((response) => response.content));
  }

  // Add other user-related methods here if needed, e.g., getUserById
  // Or a getUsersWithPagination that returns Observable<PagedResponse<User>>
}

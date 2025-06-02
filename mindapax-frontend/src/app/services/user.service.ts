import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http'; // Added HttpParams
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators'; // Added map operator
import { User } from '../models/user.model';
import { PagedResponse } from '../models/network/pagedResponse'; // Added PagedResponse
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private readonly baseUrl = environment.apiUrl + '/users'; // Assuming /users endpoint

  constructor(private http: HttpClient) { }

  getUsers(): Observable<User[]> {
    // If the dropdown needs all users, and the backend paginates by default,
    // you might need to request a large page size.
    // Example: const params = new HttpParams().set('page', '0').set('size', '100'); // Fetch up to 100 users
    // For simplicity, if the backend returns a reasonable number of users on the first page
    // for selection, or if it doesn't paginate unless requested, this will work.
    return this.http.get<PagedResponse<User>>(this.baseUrl /*, { params } */)
      .pipe(
        map(response => response.content)
      );
  }

  // Add other user-related methods here if needed, e.g., getUserById
  // Or a getUsersWithPagination that returns Observable<PagedResponse<User>>
}

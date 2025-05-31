import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';
import { HttpClient, HttpParams } from '@angular/common/http';
import { SessionQueryParams } from '../models/network/SessionQueryParams';
import { Observable } from 'rxjs';

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

    return this.http.get(this.baseUrl, { params: httpParams });
  }
}

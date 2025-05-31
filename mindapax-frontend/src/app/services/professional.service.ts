import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Professional } from '../models/professional.model';
import { PagedResponse } from '../models/network/pagedResponse';
import { catchError, map, Observable, of } from 'rxjs';
import { ProfessionalFilterParams } from '../models/network/professionalFilterParams';
import { Specialization } from '../models/enums/specialization';
import { ProfessionalStatus } from '../models/enums/professionalStatus';

@Injectable({
  providedIn: 'root',
})
export class ProfessionalService {
  private baseUrl = `${environment.apiUrl}/professionals`;

  constructor(private http: HttpClient) {}

  getAllProfessionals(
    firstName?: string,
    lastName?: string,
    specialization?: Specialization,
    experience?: number,
    availabilityDate?: Date,
    status?: ProfessionalStatus,
    page: number = 0,
    size: number = 20
  ): Observable<PagedResponse<Professional>> {
    let params = new HttpParams();
    params = params.set('page', page.toString());
    params = params.set('size', size.toString());

    if (firstName) params = params.set('firstName', firstName);
    if (lastName) params = params.set('lastName', lastName);
    if (specialization) params = params.set('specialization', specialization);
    if (experience !== undefined && experience !== null)
      params = params.set('experience', experience.toString());
    if (availabilityDate)
      params = params.set('availabilityDate', availabilityDate.toISOString());
    if (status) params = params.set('status', status);

    return this.http.get<PagedResponse<Professional>>(this.baseUrl, { params });
  }

  getProfessionalById(id: string): Observable<Professional> {
    return this.http.get<Professional>(`${this.baseUrl}/${id}`).pipe(
      map((professional) => ({
        ...professional,
        createdAt: new Date(professional.createdAt),
        statusUpdatedAt: professional.statusUpdatedAt
          ? new Date(professional.statusUpdatedAt)
          : undefined,
        experience: professional.experience
          ? professional.experience.map((exp) => ({
              ...exp,
              startDate: new Date(exp.startDate),
              endDate: exp.endDate ? new Date(exp.endDate) : undefined,
            }))
          : undefined,
        certifications: professional.certifications
          ? professional.certifications.map((cert) => ({
              ...cert,
              issueDate: cert.issueDate ? new Date(cert.issueDate) : undefined,
              expiryDate: cert.expiryDate
                ? new Date(cert.expiryDate)
                : undefined,
            }))
          : undefined,
      })),
      catchError(this.handleError<Professional>(`getProfessionalById id=${id}`))
    );
  }

  updateProfessionalStatus(
    id: number,
    status: ProfessionalStatus,
    rejectionNote?: string
  ): Observable<void> {
    const params = new HttpParams().set('status', status);
    if (rejectionNote) params.set('rejectionNote', rejectionNote);

    return this.http
      .patch<void>(`${this.baseUrl}/${id}/status`, null, {
        params: params,
      })
      .pipe(
        catchError(this.handleError<any>(`updateProfessionalStatus id=${id}`))
      );
  }

  /**
   * Handle HTTP operation that failed
   * @param operation - name of the operation that failed
   * @param result - optional value to return as the observable result
   */
  private handleError<T>(operation = 'operation', result?: T) {
    return (error: any): Observable<T> => {
      console.error(`${operation} failed: ${error.message}`);

      // Let the app keep running by returning an empty result
      return of(result as T);
    };
  }

  searchProfessionals(
    filters: ProfessionalFilterParams
  ): Observable<PagedResponse<Professional>> {
    let params = new HttpParams();

    if (filters.firstName) params = params.set('firstName', filters.firstName);
    if (filters.lastName) params = params.set('lastName', filters.lastName);
    if (filters.specialization)
      params = params.set('specialization', filters.specialization);
    if (filters.experience !== undefined && filters.experience !== null)
      params = params.set('experience', filters.experience.toString());
    if (filters.availabilityDate)
      params = params.set('availabilityDate', filters.availabilityDate);
    if (filters.status) params = params.set('status', filters.status);
    if (filters.page !== undefined)
      params = params.set('page', filters.page.toString());
    if (filters.size !== undefined)
      params = params.set('size', filters.size.toString());
    if (filters.sort) params = params.set('sort', filters.sort);

    return this.http.get<PagedResponse<Professional>>(this.baseUrl, { params });
  }
}

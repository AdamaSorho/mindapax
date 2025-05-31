import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';
import { catchError, switchMap, throwError } from 'rxjs';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);

  const accessToken = authService.getAccessToken();
  const isExpired = authService.isTokenExpired();

  let authReq = req;

  if (accessToken && !isExpired) {
    authReq = req.clone({
      setHeaders: { Authorization: `Bearer ${accessToken}` },
    });
  }

  return next(authReq).pipe(
    catchError((err) => {
      if (
        err instanceof HttpErrorResponse &&
        err.status === 401 &&
        !isExpired
      ) {
        return authService.refreshToken().pipe(
          switchMap((res: any) => {
            const refreshedReq = req.clone({
              setHeaders: { Authorization: `Bearer ${res.accessToken}` },
            });
            return next(refreshedReq);
          }),
          catchError((refreshErr) => {
            authService.logout().subscribe(); // optional cleanup
            return throwError(() => refreshErr);
          })
        );
      }
      return throwError(() => err);
    })
  );
};

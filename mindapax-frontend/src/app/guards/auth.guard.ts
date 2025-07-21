import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const token = authService.getAccessToken();
  const isExpired = authService.isTokenExpired();

  if (token && !isExpired) {
    // Token is valid, now check roles if specified
    const requiredRoles = route.data['roles'] as Array<string>;
    if (requiredRoles && requiredRoles.length > 0) {
      const userRoles = authService.getRoles(); // Assuming this returns string[] like ['USER', 'PROFESSIONAL']

      const hasRequiredRole = requiredRoles.some(role => userRoles.includes(role));

      if (hasRequiredRole) {
        return true; // User has the token and the required role
      } else {
        // User does not have the required role
        // Redirect to an unauthorized page or home/dashboard
        // For now, redirecting to home (which might be member dashboard)
        // A dedicated 'unauthorized' page would be better in a full app
        router.navigate(['/member/dashboard']); // Or any other appropriate route
        return false;
      }
    }
    return true; // Token is valid and no specific roles required for this route
  }

  // No valid token, redirect to login
  router.navigate(['/auth/login']);
  return false;
};

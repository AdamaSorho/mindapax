import { inject } from '@angular/core';
import { CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { Location } from '@angular/common';

export const authorizedGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const location = inject(Location);

  const expectedRoles = route.data?.['roles'] as string[] | undefined;

  const token = authService.getAccessToken();
  const expired = authService.isTokenExpired();
  const userRoles = authService.getRoles();

  const hasRole =
    !expectedRoles || expectedRoles.some((role) => userRoles.includes(role));

  if (token && !expired && hasRole) {
    return true;
  }

  location.back();
  return false;
};

import { Routes } from '@angular/router';
import { pagesRoutes } from './pages/pages.routes';
import { AppComponent } from './app.component';
import { authRoutes } from './auth/auth.routes';
import { featuresRoutes } from './features/features.routes';

export const routes: Routes = [
  {
    path: '',
    component: AppComponent,
    children: [...pagesRoutes, ...authRoutes, ...featuresRoutes],
  },
  { path: '**', redirectTo: '', pathMatch: 'full' },
];

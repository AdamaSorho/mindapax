import { Routes } from '@angular/router';
import { PagesComponent } from './pages.component';
import { HomeComponent } from './home/home.component';
import { AboutComponent } from './about/about.component';
import { ServicesComponent } from './services/services.component';
import { ProfessionalsComponent } from './professionals/professionals.component';
import { ProfessionalProfileComponent } from './professional-profile/professional-profile.component';
import { PricingComponent } from './pricing/pricing.component';
import { ContactComponent } from './contact/contact.component';

export const pagesRoutes: Routes = [
  {
    path: '',
    component: PagesComponent,
    children: [
      { path: '', component: HomeComponent },
      { path: 'home', redirectTo: '' },
      { path: 'about', component: AboutComponent },
      { path: 'services', component: ServicesComponent },
      { path: 'professionals', component: ProfessionalsComponent },
      { path: 'professionals/:id', component: ProfessionalProfileComponent },
      { path: 'pricing', component: PricingComponent },
      { path: 'contact', component: ContactComponent },
    ],
  },
];

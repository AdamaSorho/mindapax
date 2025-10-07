import { Routes } from '@angular/router';
import { FeaturesComponent } from './features.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { FindProfessionalComponent } from './find-professional/find-professional.component';
import { SessionsComponent } from './sessions/sessions.component';
import { MessagesComponent } from './messages/messages.component';
import { BillingComponent } from './billing/billing.component';
import { SettingsComponent } from './settings/settings.component';
import { authGuard } from '../guards/auth.guard';
// Assuming RoleGuard exists or will be created, e.g., in ../guards/role.guard
// import { roleGuard } from '../guards/role.guard';
import { ProfessionalListComponent } from './professional-list/professional-list.component';
import { ConnectionsComponent } from './connections/connections.component';
import { ScheduleSessionComponent } from './schedule-session/schedule-session.component'; // Import new component
import { ZoomMeetingComponent } from './zoom-meeting/zoom-meeting.component';
import { AiAssistantComponent } from './ai-assistant/ai-assistant.component';
import { AdminPlansComponent } from './admin-plans/admin-plans.component';
import { PackagesComponent } from './packages/packages.component';
import { MySubscriptionsComponent } from './my-subscriptions/my-subscriptions.component';

export const featuresRoutes: Routes = [
  {
    path: 'member',
    component: FeaturesComponent,
    canActivate: [authGuard],
    children: [
      { path: 'dashboard', component: DashboardComponent },
      { path: 'find-professional', component: FindProfessionalComponent },
      { path: 'sessions', component: SessionsComponent },
      { path: 'messages', component: MessagesComponent },
      { path: 'assistant', component: AiAssistantComponent },
      { path: 'billing', component: BillingComponent },
      { path: 'settings', component: SettingsComponent },
      {
        path: 'professionals',
        component: ProfessionalListComponent,
        canActivate: [authGuard],
        data: { roles: ['ADMIN'] },
      },
      { path: 'connections', component: ConnectionsComponent },
      {
        path: 'schedule-session',
        component: ScheduleSessionComponent,
        // Assuming authGuard protects parent, and roleGuard for specific role
        // canActivate: [authGuard, roleGuard], // If roleGuard is separate
        canActivate: [authGuard], // If authGuard itself can check roles or a combined guard is used
        data: { roles: ['PROFESSIONAL'] }, // Data for RoleGuard if it uses it
      },
      {
        path: 'zoom-call', // Path for the zoom meeting page
        component: ZoomMeetingComponent
        // All parameters (sdkKey, meetingNumber, signature, userName, userEmail)
        // will be passed as query parameters during navigation.
        // authGuard is implicitly applied due to parent.
      },
      { path: 'admin/plans', component: AdminPlansComponent, data: { roles: ['ADMIN'] } },
      { path: 'packages', component: PackagesComponent },
      { path: 'subscriptions', component: MySubscriptionsComponent },
    ],
  },
];

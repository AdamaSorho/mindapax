import { CommonModule, NgClass, NgIf } from '@angular/common';
import { Component, OnInit } from '@angular/core'; // Import OnInit
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../../../services/auth.service';
import { Role } from '../../../models/enums/role'; // Import Role

@Component({
  selector: 'app-member-sidebar',
  imports: [NgClass, NgIf, RouterLink, RouterLinkActive, CommonModule],
  templateUrl: './member-sidebar.component.html',
  styleUrl: './member-sidebar.component.css',
})
export class MemberSidebarComponent implements OnInit {
  // Implement OnInit
  isSidebarCollapsed = false;
  userRoles: string[] = []; // Add userRoles property

  // Add sidebarLinks property
  public sidebarLinks = [
    {
      label: 'Home',
      route: '/member/dashboard',
      icon: 'home-outline',
      allowedRoles: ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN'],
    },
    {
      label: 'Find a Professional',
      route: '/member/find-professional',
      icon: 'search-outline',
      allowedRoles: ['ROLE_USER'],
    },
    {
      label: 'My Sessions',
      route: '/member/sessions',
      icon: 'calendar-outline',
      allowedRoles: ['ROLE_USER', 'ROLE_PROFESSIONAL'],
    },
    {
      label: 'Messages',
      route: '/member/messages',
      icon: 'paper-plane-outline',
      allowedRoles: ['ROLE_USER', 'ROLE_PROFESSIONAL'],
    },
    {
      label: 'AI Assistant',
      route: '/member/assistant',
      icon: 'robot-outline',
      allowedRoles: ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN'],
    },
    {
      label: 'Connections',
      route: '/member/connections',
      icon: 'person-add-outline',
      allowedRoles: ['ROLE_PROFESSIONAL'],
    },
    {
      label: 'Professionals',
      route: '/member/professionals',
      icon: 'people-outline',
      allowedRoles: ['ROLE_ADMIN'],
    },
    {
      label: 'Admin: Plans',
      route: '/member/admin/plans',
      icon: 'settings-outline',
      allowedRoles: ['ROLE_ADMIN'],
    },
    {
      label: 'Billing',
      route: '/member/billing',
      icon: 'card-outline',
      allowedRoles: ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN'],
    },
    {
      label: 'Packages',
      route: '/member/packages',
      icon: 'pricetags-outline',
      allowedRoles: ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN'],
    },
    {
      label: 'My Subscriptions',
      route: '/member/subscriptions',
      icon: 'receipt-outline',
      allowedRoles: ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN'],
    },
    {
      label: 'Settings',
      route: '/member/settings',
      icon: 'settings-outline',
      allowedRoles: ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN'],
    },
    // Logout is handled by a separate button/method.
  ];

  constructor(private authService: AuthService, private router: Router) {}

  ngOnInit(): void {
    this.userRoles = this.authService.getRoles();
  }

  toggleSidebar(): void {
    this.isSidebarCollapsed = !this.isSidebarCollapsed;
  }

  public canShowLink(allowedRoles: string[]): boolean {
    if (!allowedRoles || allowedRoles.length === 0) {
      return true;
    }
    return allowedRoles.some((role) => this.userRoles.includes(role));
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/auth/login']), // Ensure this path is correct
      error: (err) => console.error('Logout failed', err),
    });
  }
}

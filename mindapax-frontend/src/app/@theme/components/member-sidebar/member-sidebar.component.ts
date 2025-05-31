import { NgClass, NgIf } from '@angular/common';
import { Component } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-member-sidebar',
  imports: [NgClass, NgIf, RouterLink],
  templateUrl: './member-sidebar.component.html',
  styleUrl: './member-sidebar.component.css',
})
export class MemberSidebarComponent {
  isSidebarCollapsed = false;

  constructor(private authService: AuthService, private router: Router) {}

  toggleSidebar(): void {
    this.isSidebarCollapsed = !this.isSidebarCollapsed;
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: (err) => console.error('Logout failed', err),
    });
  }
}

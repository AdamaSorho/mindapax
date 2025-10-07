import { Component, OnInit } from '@angular/core';
import { DashboardService } from '../../services/dashboard.service';
import { WellnessStats } from '../../models/wellness-stats.model';
import { Recommendation } from '../../models/recommendation.model';
import { Session } from '../../models/session.model';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { SubscriptionsService, SubscriptionDTO } from '../../services/subscriptions.service';

@Component({
  selector: 'app-dashboard',
  imports: [CommonModule, RouterLink],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css',
})
export class DashboardComponent implements OnInit {
  userName: string | null = '';
  upcomingSessions: Session[] = [];
  recommendations: Recommendation[] = [];
  wellnessStats: WellnessStats | null = null;
  hasActiveSubscription = true;

  isLoading = true;

  constructor(
    private dashboardService: DashboardService,
    private authService: AuthService,
    private subsService: SubscriptionsService,
  ) {}

  ngOnInit(): void {
    this.loadDashboardData();
    this.userName = this.authService.getUsername();
  }

  private loadDashboardData(): void {
    this.isLoading = true;

    // Load sessions
    this.dashboardService.getUserSessions().subscribe((sessions) => {
      this.upcomingSessions = sessions;
      this.checkIfDataLoaded();
    });

    // Load recommendations
    this.dashboardService.getRecommendations().subscribe((recommendations) => {
      this.recommendations = recommendations;
      this.checkIfDataLoaded();
    });

    // Load wellness stats
    this.dashboardService.getWellnessStats().subscribe((stats) => {
      this.wellnessStats = stats;
      this.checkIfDataLoaded();
    });

    // Load subscription status (lightweight)
    this.subsService.mySubscriptions().subscribe({
      next: (subs: SubscriptionDTO[]) => {
        this.hasActiveSubscription = subs.some(s => s.status === 'ACTIVE');
      },
      error: () => {
        this.hasActiveSubscription = true; // hide banner on error
      },
    });
  }

  private checkIfDataLoaded(): void {
    // Check if all data is loaded
    if (this.upcomingSessions && this.recommendations && this.wellnessStats) {
      this.isLoading = false;
    }
  }

  refreshRecommendations(): void {
    this.dashboardService.getRecommendations().subscribe((recommendations) => {
      this.recommendations = recommendations;
    });
  }
}

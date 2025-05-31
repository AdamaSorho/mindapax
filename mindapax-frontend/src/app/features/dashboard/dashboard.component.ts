import { Component, OnInit } from '@angular/core';
import { DashboardService } from '../../services/dashboard.service';
import { WellnessStats } from '../../models/wellness-stats.model';
import { Recommendation } from '../../models/recommendation.model';
import { Session } from '../../models/session.model';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-dashboard',
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css',
})
export class DashboardComponent implements OnInit {
  userName: string | null = '';
  upcomingSessions: Session[] = [];
  recommendations: Recommendation[] = [];
  wellnessStats: WellnessStats | null = null;

  isLoading = true;

  constructor(
    private dashboardService: DashboardService,
    private authService: AuthService
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

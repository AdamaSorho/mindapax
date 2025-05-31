import { Injectable } from '@angular/core';
import { delay, Observable, of } from 'rxjs';
import { WellnessStats } from '../models/wellness-stats.model';
import { Recommendation } from '../models/recommendation.model';
import { Session } from '../models/session.model';
import { SessionMode } from '../models/enums/SessionFilter';

@Injectable({
  providedIn: 'root',
})
export class DashboardService {
  private mockSessions: Session[] = [
    {
      id: 1,
      professionalName: 'Dr. Sarah Chen',
      professionalImage: 'assets/images/professionals/sarah.jpg',
      specialization: 'Cognitive Behavioral Therapy',
      date: new Date(2025, 2, 24), // March 24, 2025
      time: '10:00 AM',
      mode: SessionMode.VIDEO,
    },
    {
      id: 2,
      professionalName: 'Michael Rodriguez',
      professionalImage: 'assets/images/professionals/michael.jpg',
      specialization: 'Financial Planning',
      date: new Date(2025, 2, 26), // March 26, 2025
      time: '2:30 PM',
      mode: SessionMode.CHAT,
    },
  ];

  private mockRecommendations: Recommendation[] = [
    {
      id: 1,
      title: 'Morning Meditation',
      description:
        'Start your day with a 10-minute mindfulness practice to reduce stress.',
      icon: 'brain',
      category: 'mental',
    },
    {
      id: 2,
      title: 'Expense Tracking',
      description:
        'Review your weekly spending patterns to identify saving opportunities.',
      icon: 'wallet',
      category: 'financial',
    },
    {
      id: 3,
      title: 'Desk Stretches',
      description:
        'Try these 5 simple stretches to reduce neck and shoulder tension.',
      icon: 'activity',
      category: 'physical',
    },
  ];

  private mockWellnessStats: WellnessStats = {
    mental: {
      status: "You're making great progress!",
      progress: 75,
    },
    physical: {
      status: '2 goals completed this week',
      progress: 60,
    },
    financial: {
      status: 'On track with your budget',
      progress: 85,
    },
  };

  constructor() {}

  getUserSessions(): Observable<Session[]> {
    // Simulate API call with delay
    return of(this.mockSessions).pipe(delay(300));
  }

  getRecommendations(): Observable<Recommendation[]> {
    // Simulate API call with delay
    return of(this.mockRecommendations).pipe(delay(500));
  }

  getWellnessStats(): Observable<WellnessStats> {
    // Simulate API call with delay
    return of(this.mockWellnessStats).pipe(delay(400));
  }
}

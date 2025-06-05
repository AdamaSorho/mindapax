import { Component, OnInit } from '@angular/core';
import { Session } from '../../models/session.model';
import { NgClass, NgFor, NgIf, DatePipe } from '@angular/common'; // Added DatePipe
import { SessionService } from '../../services/session.service';
import { AuthService } from '../../services/auth.service';
import {
  SessionStatus,
  SessionTimeFilter,
} from '../../models/enums/SessionFilter';
import { Router } from '@angular/router';

@Component({
  selector: 'app-sessions',
  imports: [NgFor, NgIf, NgClass, DatePipe], // Added DatePipe to imports
  templateUrl: './sessions.component.html',
  styleUrl: './sessions.component.css',
})
export class SessionsComponent implements OnInit {
  upcomingSessions: Session[] = [];
  pastSessions: Session[] = [];
  activeTab: 'upcoming' | 'past' = 'upcoming';
  loading: boolean = true;

  constructor(
    private sessionService: SessionService,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.fetchUpcomingSessions();
    this.fetchPastSessions();
  }

  public getCalculatedEndTime(session: Session): Date | null {
    if (!session.startTime || session.durationMinutes == null) {
      return null;
    }
    const startTimeDate = new Date(session.startTime);
    const duration = Number(session.durationMinutes);
    if (isNaN(duration)) {
      return null;
    }
    return new Date(startTimeDate.getTime() + duration * 60000); // 60000 ms in a minute
  }

  isToday(session: Session): boolean {
    if (!session.startTime) {
      return false;
    }
    const sessionStartDate = new Date(session.startTime);
    const today = new Date();

    return (
      sessionStartDate.getFullYear() === today.getFullYear() &&
      sessionStartDate.getMonth() === today.getMonth() &&
      sessionStartDate.getDate() === today.getDate()
    );
  }

  fetchUpcomingSessions(): void {
    this.loading = true;
    this.sessionService
      .getSessions({
        userId: this.authService.getUserId(),
        filter: SessionTimeFilter.UPCOMING,
        date: new Date().toISOString(),
        status: SessionStatus.SCHEDULED,
        page: 1,
        size: 10,
        sort: 'startTime,asc',
      })
      .subscribe({
        next: (response) => {
          this.upcomingSessions = response;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error fetching sessions:', error);
          this.loading = false;
        },
      });
  }

  fetchPastSessions(): void {
    this.loading = true;
    this.sessionService
      .getSessions({
        userId: this.authService.getUserId(),
        filter: SessionTimeFilter.PAST,
        date: new Date().toISOString(),
        status: SessionStatus.SCHEDULED,
        page: 1,
        size: 10,
        sort: 'startTime,asc',
      })
      .subscribe({
        next: (response) => {
          this.pastSessions = response;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error fetching sessions:', error);
          this.loading = false;
        },
      });
  }

  setActiveTab(tab: 'upcoming' | 'past'): void {
    this.activeTab = tab;
  }

  joinSession(sessionId: number | undefined): void {
    // In a real app, this would navigate to the video/chat interface
    console.log(`Joining session with ID: ${sessionId}`);
  }

  rescheduleSession(sessionId: number | undefined): void {
    // In a real app, this would open a rescheduling modal/page
    console.log(`Rescheduling session with ID: ${sessionId}`);
  }

  cancelSession(sessionId: number | undefined): void {
    // In a real app, this would make an API call to cancel the session
    console.log(`Canceling session with ID: ${sessionId}`);
  }

  viewPastSession(sessionId: number | undefined): void {
    // In a real app, this would navigate to the session details page
    console.log(`Viewing past session with ID: ${sessionId}`);
  }

  bookNewSession(): void {
    this.router.navigate(['/member/schedule-session']);
  }

  formatDateToRelative(dateString: string | Date): string {
    // Accept string or Date
    const now = new Date();
    const sessionDate = new Date(dateString); // Works with ISO string or Date object
    const diffTime = Math.abs(sessionDate.getTime() - now.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return 'Today';
    } else if (diffDays === 1) {
      return sessionDate > now ? 'Tomorrow' : 'Yesterday';
    } else if (diffDays < 7) {
      const day = sessionDate.toLocaleDateString('en-US', { weekday: 'long' });
      return day;
    } else {
      return sessionDate.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
      });
    }
  }

  getSessionTypeIcon(type: string): string {
    switch (type) {
      case 'video':
        return 'video-camera';
      case 'chat':
        return 'chat-bubble-left-right';
      case 'messaging':
        return 'envelope';
      default:
        return 'question-mark-circle';
    }
  }

  // Helper method to generate mock data
  // private getMockSessions(): Session[] {
  //   const today = new Date();
  //   const yesterday = new Date(today);
  //   yesterday.setDate(yesterday.getDate() - 1);

  //   const tomorrow = new Date(today);
  //   tomorrow.setDate(tomorrow.getDate() + 1);

  //   const nextWeek = new Date(today);
  //   nextWeek.setDate(nextWeek.getDate() + 7);

  //   const lastWeek = new Date(today);
  //   lastWeek.setDate(lastWeek.getDate() - 7);

  //   const twoWeeksAgo = new Date(today);
  //   twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);

  //   return [
  //     {
  //       id: 1,
  //       professionalName: 'Dr. Sarah Johnson',
  //       professionalImage: '/api/placeholder/150/150',
  //       specialization: 'Mental Health',
  //       date: tomorrow,
  //       startTime: '10:00 AM',
  //       endTime: '11:00 AM',
  //       status: 'upcoming',
  //       type: 'video',
  //       notes: 'Follow-up on stress management techniques',
  //     },
  //     {
  //       id: 2,
  //       professionalName: 'Michael Chang, CFA',
  //       professionalImage: '/api/placeholder/150/150',
  //       specialization: 'Financial Coaching',
  //       date: nextWeek,
  //       startTime: '3:00 PM',
  //       endTime: '4:00 PM',
  //       status: 'upcoming',
  //       type: 'video',
  //     },
  //     {
  //       id: 3,
  //       professionalName: 'Emma Martinez',
  //       professionalImage: '/api/placeholder/150/150',
  //       specialization: 'Physical Wellness',
  //       date: yesterday,
  //       startTime: '2:00 PM',
  //       endTime: '3:00 PM',
  //       status: 'completed',
  //       type: 'video',
  //       notes: 'Discussed new exercise routine',
  //     },
  //     {
  //       id: 4,
  //       professionalName: 'Dr. Sarah Johnson',
  //       professionalImage: '/api/placeholder/150/150',
  //       specialization: 'Mental Health',
  //       date: lastWeek,
  //       startTime: '11:00 AM',
  //       endTime: '12:00 PM',
  //       status: 'completed',
  //       type: 'chat',
  //     },
  //     {
  //       id: 5,
  //       professionalName: 'Robert Davis',
  //       professionalImage: '/api/placeholder/150/150',
  //       specialization: 'Career Counseling',
  //       date: twoWeeksAgo,
  //       startTime: '4:00 PM',
  //       endTime: '5:00 PM',
  //       status: 'canceled',
  //       type: 'messaging',
  //     },
  //     {
  //       id: 6,
  //       professionalName: 'Sophia Lee',
  //       professionalImage: '/api/placeholder/150/150',
  //       specialization: 'Nutrition',
  //       date: today,
  //       startTime: '5:00 PM',
  //       endTime: '6:00 PM',
  //       status: 'upcoming',
  //       type: 'video',
  //     },
  //   ];
  // }
}

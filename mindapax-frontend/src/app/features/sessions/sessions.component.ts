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
import { SubscriptionsService, SubscriptionDTO } from '../../services/subscriptions.service';
import { ZoomSignatureResponse } from '../../models/zoom-signature-response.model';

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
  remainingCredits?: number;

  currentPage = 0;
  pageSize = 10;

  constructor(
    private sessionService: SessionService,
    private authService: AuthService,
    private router: Router,
    private subsService: SubscriptionsService,
  ) {}

  ngOnInit(): void {
    this.fetchUpcomingSessions();
    this.fetchPastSessions();
    this.loadSubscriptionCredits();
  }

  loadSubscriptionCredits(): void {
    this.subsService.mySubscriptions().subscribe({
      next: (subs: SubscriptionDTO[]) => {
        const active = subs.find(s => s.status === 'ACTIVE');
        if (active && active.remainingSessions != null) {
          this.remainingCredits = active.remainingSessions;
        }
      },
      error: () => {}
    });
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
        page: this.currentPage,
        size: this.pageSize,
        sort: 'startTime,asc',
      })
      .subscribe({
        next: (response) => {
          this.upcomingSessions = response.content;
          console.log('Upcoming sessions:', this.upcomingSessions);
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
        page: this.currentPage,
        size: this.pageSize,
        sort: 'startTime,asc',
      })
      .subscribe({
        next: (response) => {
          this.pastSessions = response.content;
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

  public isJoinable(session: Session): boolean {
    if (
      !session ||
      session.mode?.toUpperCase() !== 'VIDEO' ||
      session.status?.toUpperCase() !== 'SCHEDULED'
    ) {
      return false;
    }
    const now = new Date().getTime();
    // Ensure startTime is valid before creating a Date object
    if (!session.startTime) return false;
    const startTime = new Date(session.startTime).getTime();
    if (isNaN(startTime)) return false; // Invalid date for startTime

    // Allow joining if session starts now or in the past (up to its duration), or up to 15 minutes before.
    const joinWindowStart = startTime - 15 * 60 * 1000; // 15 minutes before

    // Ensure durationMinutes is valid
    const durationMinutes = Number(session.durationMinutes);
    if (isNaN(durationMinutes) || durationMinutes <= 0) return false; // Defaulting to 60 if invalid is risky for window end

    const sessionDuration = durationMinutes * 60 * 1000;
    const joinWindowEnd = startTime + sessionDuration; // Allow joining until session ends

    return now >= joinWindowStart && now <= joinWindowEnd;
  }

  public joinVideoCall(session: Session): void {
    if (!session || !session.id) {
      console.error('Session or Session ID is undefined.');
      alert('Session or Session ID is undefined.');
      // TODO: Show user-friendly error
      return;
    }

    this.loading = true; // Show loading indicator
    this.sessionService
      .getZoomMeetingSignature(session.id.toString())
      .subscribe({
        next: (zoomResponse: ZoomSignatureResponse) => {
          this.loading = false;
          // TODO: Get actual userName and userEmail from AuthService
          // const currentUser = this.authService.getCurrentUser(); // Assuming AuthService has such a method
          const userName = this.authService.getUsername()
            ? this.authService.getUsername()
            : 'Mindapax User'; // Placeholder
          const userEmail = this.authService.getUserEmail
            ? this.authService.getUserEmail()
            : ''; // Placeholder - Zoom SDK might need it

          this.router.navigate(['/member/zoom-call'], {
            queryParams: {
              sdkKey: zoomResponse.apiKey,
              meetingNumber: zoomResponse.meetingNumber,
              signature: zoomResponse.signature,
              passWord: zoomResponse.password,
              userName: userName,
              userEmail: userEmail,
            },
          });
        },
        error: (error) => {
          this.loading = false;
          console.error('Failed to get Zoom meeting signature:', error);
          // TODO: Show user-friendly error (e.g., using a toast notification service)
          alert('Failed to start video call. Please try again later.');
        },
      });
  }

  // The old joinSession can be removed or adapted if it was meant for other session types.
  // For this subtask, we are focusing on adding joinVideoCall.
  // joinSession(sessionId: number | undefined): void {
  //   // In a real app, this would navigate to the video/chat interface
  //   console.log(`Joining session with ID: ${sessionId}`);
  // }

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
    console.log('dateString:', dateString);
    // Accept string or Date
    const now = new Date();
    const sessionDate = new Date(dateString); // Works with ISO string or Date object
    const diffTime = Math.abs(sessionDate.getTime() - now.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    console.log('diffDays:', diffDays);
    console.log('sessionDate:', sessionDate);
    console.log('now:', now);
    console.log('diffTime:', diffTime);

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
}

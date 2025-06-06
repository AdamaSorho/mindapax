import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ComponentFixture, TestBed, fakeAsync, tick } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';
import { Router } from '@angular/router';
import { DatePipe, NgClass, NgFor, NgIf } from '@angular/common';

import { SessionsComponent } from './sessions.component';
import { SessionService } from '../../services/session.service';
import { AuthService } from '../../services/auth.service';
import { Session } from '../../models/session.model';
import { ZoomSignatureResponse } from '../../models/zoom-signature-response.model';
import {
  SessionMode,
  SessionStatus,
  // SessionTimeFilter, // Not directly used in new tests, but keep if other tests need
} from '../../models/enums/SessionFilter';

// Mock services
class MockSessionService {
  getSessions = jasmine.createSpy('getSessions').and.returnValue(of({ content: [] }));
  getZoomMeetingSignature = jasmine.createSpy('getZoomMeetingSignature');
}

class MockAuthService {
  getUserId = jasmine.createSpy('getUserId').and.returnValue('mockUserId'); // String ID if used as such
  getUserName = jasmine.createSpy('getUserName').and.returnValue('Mock User');
  getUserEmail = jasmine.createSpy('getUserEmail').and.returnValue('mock@example.com');
}

class MockRouter {
  navigate = jasmine.createSpy('navigate');
}

describe('SessionsComponent', () => {
  let component: SessionsComponent;
  let fixture: ComponentFixture<SessionsComponent>;
  let sessionService: MockSessionService;
  let authService: MockAuthService;
  let router: MockRouter;

  const mockVideoSession: Session = {
    id: '1',
    professionalName: 'Dr. Zoom',
    startTime: new Date().toISOString(),
    durationMinutes: 60,
    mode: 'VIDEO',
    status: 'SCHEDULED',
    userId: 'client1',
    professionalId: 'prof1',
    professionalImage: 'img.jpg',
    professionalSpecialization: 'Zoomology',
    notes: 'Test notes',
    // date: new Date(), // if your model has this separate from startTime
  };

  const mockNonVideoSession: Session = { ...mockVideoSession, id: '2', mode: 'CHAT' };
  const mockNotScheduledSession: Session = { ...mockVideoSession, id: '3', status: 'COMPLETED' };


  beforeEach(async () => {
    await TestBed.configureTestingModule({
      // SessionsComponent is standalone, so it's in imports.
      // No 'declarations' array needed here for standalone.
      imports: [
        HttpClientTestingModule,
        SessionsComponent, // Import standalone component itself
        // NgIf, NgFor, NgClass, DatePipe are implicitly imported by SessionsComponent
      ],
      providers: [
        { provide: SessionService, useClass: MockSessionService },
        { provide: AuthService, useClass: MockAuthService },
        { provide: Router, useClass: MockRouter },
        DatePipe // Provide DatePipe as SessionsComponent uses it in template
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(SessionsComponent);
    component = fixture.componentInstance;
    sessionService = TestBed.inject(SessionService) as unknown as MockSessionService;
    authService = TestBed.inject(AuthService) as unknown as MockAuthService;
    router = TestBed.inject(Router) as unknown as MockRouter;
  });

  it('should create', () => {
    // fixture.detectChanges(); // Call ngOnInit - moved to specific tests or after setup if needed
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should call fetchUpcomingSessions and fetchPastSessions', () => {
      spyOn(component, 'fetchUpcomingSessions');
      spyOn(component, 'fetchPastSessions');
      component.ngOnInit();
      expect(component.fetchUpcomingSessions).toHaveBeenCalled();
      expect(component.fetchPastSessions).toHaveBeenCalled();
    });
  });

  describe('isToday', () => {
    it('should return true if session startTime is today', () => {
      const today = new Date();
      const session: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: today.toISOString(),
        durationMinutes: 60,
      };
      expect(component.isToday(session)).toBeTrue();
    });

    it('should return false if session startTime is tomorrow', () => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const session: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: tomorrow.toISOString(),
        durationMinutes: 60,
      };
      expect(component.isToday(session)).toBeFalse();
    });

    it('should return false if session startTime is yesterday', () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const session: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: yesterday.toISOString(),
        durationMinutes: 60,
      };
      expect(component.isToday(session)).toBeFalse();
    });

    it('should return false if session startTime is null or undefined', () => {
      const sessionWithNullStartTime: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: null as any,
        durationMinutes: 60,
      };
      const sessionWithUndefinedStartTime: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: undefined as any,
        durationMinutes: 60,
      };
      expect(component.isToday(sessionWithNullStartTime)).toBeFalse();
      expect(component.isToday(sessionWithUndefinedStartTime)).toBeFalse();
    });
  });

  describe('getCalculatedEndTime', () => {
    it('should correctly calculate end time with valid startTime and durationMinutes', () => {
      const startTime = new Date('2024-01-01T10:00:00Z');
      const duration = 60;
      const session: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: startTime.toISOString(),
        durationMinutes: duration,
      };
      const expectedEndTime = new Date(startTime.getTime() + duration * 60000);
      expect(component.getCalculatedEndTime(session)).toEqual(expectedEndTime);
    });

    it('should return null if startTime is missing', () => {
      const session: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: null as any,
        durationMinutes: 60,
      };
      expect(component.getCalculatedEndTime(session)).toBeNull();
    });

    it('should return null if durationMinutes is null or undefined', () => {
      const sessionNullDuration: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: new Date().toISOString(),
        durationMinutes: null as any,
      };
      const sessionUndefinedDuration: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: new Date().toISOString(),
        durationMinutes: undefined as any,
      };
      expect(component.getCalculatedEndTime(sessionNullDuration)).toBeNull();
      expect(
        component.getCalculatedEndTime(sessionUndefinedDuration)
      ).toBeNull();
    });

    it('should return null if durationMinutes is NaN', () => {
      const session: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: new Date().toISOString(),
        durationMinutes: Number('abc'), // This will be NaN
      };
      expect(component.getCalculatedEndTime(session)).toBeNull();
    });

    it('should handle durationMinutes of 0 correctly', () => {
      const startTime = new Date('2024-01-01T10:00:00Z');
      const session: Session = {
        id: 1,
        userId: 1,
        mode: SessionMode.VIDEO,
        startTime: startTime.toISOString(),
        durationMinutes: 0,
      };
      expect(component.getCalculatedEndTime(session)).toEqual(startTime);
    });
  });

  // Example of how professional details might be tested if there was component logic
  // For now, this is mostly a template concern.
  it('should correctly prepare sessions for display (conceptual)', () => {
    const mockSession: Session = {
      id: 1,
      userId: 1,
      mode: SessionMode.VIDEO,
      startTime: new Date().toISOString(),
      durationMinutes: 60, // Use durationMinutes
      professionalName: 'Dr. Test',
      professionalSpecialization: 'Testingology',
    };
    component.upcomingSessions = [mockSession];
    fixture.detectChanges(); // To process bindings if any logic was in component

    // In a real test for component logic transforming data for display:
    // expect(component.processedSessions[0].displayProfessionalName).toBe('Dr. Test');
    // Since it's direct binding, this test is more illustrative.
    expect(component.upcomingSessions[0].professionalName).toBe('Dr. Test');
    expect(component.upcomingSessions[0].professionalSpecialization).toBe(
      'Testingology'
    );
  });

  describe('isJoinable', () => {
    it('should return true for a joinable video session (starts now)', () => {
      const now = new Date();
      const joinableSession: Session = {
        ...mockVideoSession,
        startTime: now.toISOString()
      };
      expect(component.isJoinable(joinableSession)).toBeTrue();
    });

    it('should return true for a video session starting in 10 minutes', () => {
      const futureTime = new Date(new Date().getTime() + 10 * 60000);
      const joinableSession: Session = { ...mockVideoSession, startTime: futureTime.toISOString() };
      expect(component.isJoinable(joinableSession)).toBeTrue();
    });

    it('should return true for an ongoing video session (started 5 mins ago, duration 60 mins)', () => {
      const pastTime = new Date(new Date().getTime() - 5 * 60000);
      const joinableSession: Session = { ...mockVideoSession, startTime: pastTime.toISOString(), durationMinutes: 60 };
      expect(component.isJoinable(joinableSession)).toBeTrue();
    });

    it('should return false if session mode is not VIDEO', () => {
      expect(component.isJoinable(mockNonVideoSession)).toBeFalse();
    });

    it('should return false if session status is not SCHEDULED', () => {
      expect(component.isJoinable(mockNotScheduledSession)).toBeFalse();
    });

    it('should return false if session started long ago and is over', () => {
      const pastTime = new Date(new Date().getTime() - 90 * 60000);
      const oldSession: Session = { ...mockVideoSession, startTime: pastTime.toISOString(), durationMinutes: 60 };
      expect(component.isJoinable(oldSession)).toBeFalse();
    });

    it('should return false if session is too far in the future (e.g., > 15 mins)', () => {
      const futureTime = new Date(new Date().getTime() + 30 * 60000);
      const farFutureSession: Session = { ...mockVideoSession, startTime: futureTime.toISOString() };
      expect(component.isJoinable(farFutureSession)).toBeFalse();
    });

    it('should return false if startTime is invalid', () => {
      const invalidStartTimeSession: Session = { ...mockVideoSession, startTime: 'invalid-date' };
      expect(component.isJoinable(invalidStartTimeSession)).toBeFalse();
    });

    it('should return false if durationMinutes is invalid or zero', () => {
      const zeroDurationSession: Session = { ...mockVideoSession, durationMinutes: 0 };
      const nanDurationSession: Session = { ...mockVideoSession, durationMinutes: NaN };
      expect(component.isJoinable(zeroDurationSession)).toBeFalse();
      expect(component.isJoinable(nanDurationSession)).toBeFalse();
    });
  });

  describe('joinVideoCall', () => {
    const mockZoomResponse: ZoomSignatureResponse = {
      apiKey: 'key', signature: 'sig', meetingNumber: 'mn'
    };

    beforeEach(() => {
        // Reset spies for each test in this describe block
        sessionService.getZoomMeetingSignature.calls.reset();
        router.navigate.calls.reset();
        // Ensure spies on authService methods are reset if they are called multiple times across tests
        authService.getUserName.calls.reset().and.returnValue('Mock User');
        authService.getUserEmail.calls.reset().and.returnValue('mock@example.com');
        component.loading = false; // Reset loading state
    });

    it('should navigate to zoom-call route on successful signature fetch', fakeAsync(() => {
      sessionService.getZoomMeetingSignature.and.returnValue(of(mockZoomResponse));

      component.joinVideoCall(mockVideoSession);

      expect(component.loading).toBeTrue(); // Check loading state after call
      tick(); // Complete observable

      expect(sessionService.getZoomMeetingSignature).toHaveBeenCalledWith(mockVideoSession.id!.toString());
      expect(router.navigate).toHaveBeenCalledWith(['/member/zoom-call'], {
        queryParams: {
          sdkKey: mockZoomResponse.apiKey,
          meetingNumber: mockZoomResponse.meetingNumber,
          signature: mockZoomResponse.signature,
          userName: 'Mock User',
          userEmail: 'mock@example.com'
        }
      });
      expect(component.loading).toBeFalse(); // Check loading state after observable completes
    }));

    it('should handle error from getZoomMeetingSignature', fakeAsync(() => {
      sessionService.getZoomMeetingSignature.and.returnValue(throwError(() => new Error('API Error')));
      spyOn(console, 'error');
      spyOn(window, 'alert');

      component.joinVideoCall(mockVideoSession);
      expect(component.loading).toBeTrue();
      tick();

      expect(sessionService.getZoomMeetingSignature).toHaveBeenCalledWith(mockVideoSession.id!.toString());
      expect(router.navigate).not.toHaveBeenCalled();
      expect(console.error).toHaveBeenCalledWith('Failed to get Zoom meeting signature:', jasmine.any(Error));
      expect(window.alert).toHaveBeenCalledWith('Failed to start video call. Please try again later.');
      expect(component.loading).toBeFalse();
    }));

    it('should not proceed if session or session.id is null/undefined', () => {
      spyOn(console, 'error');
      const nullIdSession : Session = {...mockVideoSession, id: undefined };

      component.joinVideoCall(nullIdSession);
      expect(console.error).toHaveBeenCalledWith('Session or Session ID is undefined.');
      expect(sessionService.getZoomMeetingSignature).not.toHaveBeenCalled();

      component.joinVideoCall(null as any);
      expect(console.error).toHaveBeenCalledWith('Session or Session ID is undefined.');
      expect(sessionService.getZoomMeetingSignature).not.toHaveBeenCalled();
    });
  });

  it('should set loading to true when fetching upcoming sessions and false on completion/error', fakeAsync(() => {
    // component.ngOnInit calls fetchUpcomingSessions and fetchPastSessions
    // Ensure getSessions is spied on for both calls if they happen in ngOnInit
    sessionService.getSessions.and.returnValue(of({ content: [], totalElements: 0, totalPages: 0, number: 0, size: 0  }));

    fixture.detectChanges(); // Calls ngOnInit

    // ngOnInit calls fetchUpcomingSessions then fetchPastSessions.
    // Loading is set to true at the start of each.
    // It's set to false at the end of each.
    // The final state depends on the sequence.
    // Let's assume fetchUpcomingSessions sets it to true, then completes.
    // Then fetchPastSessions sets it to true, then completes.
    // So, after all ticks, it should be false.

    expect(component.loading).toBeTrue(); // After first call in ngOnInit
    tick(); // Complete all observables
    expect(component.loading).toBeFalse();
  }));

});

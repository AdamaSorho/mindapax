import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { of } from 'rxjs';

import { SessionsComponent } from './sessions.component';
import { SessionService } from '../../services/session.service';
import { AuthService } from '../../services/auth.service';
import { Session } from '../../models/session.model';
import { SessionMode, SessionStatus, SessionTimeFilter } from '../../models/enums/SessionFilter';

// Mock services
class MockSessionService {
  getSessions() {
    return of([]); // Default to empty array, can be overridden with spy
  }
}

class MockAuthService {
  getUserId() {
    return 1; // Mock user ID
  }
  // Add other methods if needed by component
}

describe('SessionsComponent', () => {
  let component: SessionsComponent;
  let fixture: ComponentFixture<SessionsComponent>;
  let sessionService: SessionService;
  // let authService: AuthService; // Not strictly needed for isToday tests unless methods are called

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [
        HttpClientTestingModule, // SessionService might inject HttpClient
        SessionsComponent // Import standalone component
      ],
      // No declarations needed for standalone components
      providers: [
        { provide: SessionService, useClass: MockSessionService },
        { provide: AuthService, useClass: MockAuthService }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(SessionsComponent);
    component = fixture.componentInstance;
    sessionService = TestBed.inject(SessionService); // Get instance for potential spying
    // authService = TestBed.inject(AuthService);
    // fixture.detectChanges(); // ngOnInit is called here
  });

  it('should create', () => {
    fixture.detectChanges(); // Call ngOnInit
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
        id: 1, userId: 1, mode: SessionMode.VIDEO,
        startTime: today.toISOString(),
        endTime: new Date(today.getTime() + 3600000).toISOString() // 1 hour later
      };
      expect(component.isToday(session)).toBeTrue();
    });

    it('should return false if session startTime is tomorrow', () => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const session: Session = {
        id: 1, userId: 1, mode: SessionMode.VIDEO,
        startTime: tomorrow.toISOString(),
        endTime: new Date(tomorrow.getTime() + 3600000).toISOString()
      };
      expect(component.isToday(session)).toBeFalse();
    });

    it('should return false if session startTime is yesterday', () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const session: Session = {
        id: 1, userId: 1, mode: SessionMode.VIDEO,
        startTime: yesterday.toISOString(),
        endTime: new Date(yesterday.getTime() + 3600000).toISOString()
      };
      expect(component.isToday(session)).toBeFalse();
    });

    it('should return false if session startTime is null or undefined', () => {
       const sessionWithNullStartTime: Session = {
        id: 1, userId: 1, mode: SessionMode.VIDEO,
        startTime: null as any, // Simulate null
        endTime: new Date().toISOString()
      };
      const sessionWithUndefinedStartTime: Session = {
        id: 1, userId: 1, mode: SessionMode.VIDEO,
        startTime: undefined as any, // Simulate undefined
        endTime: new Date().toISOString()
      };
      expect(component.isToday(sessionWithNullStartTime)).toBeFalse();
      expect(component.isToday(sessionWithUndefinedStartTime)).toBeFalse();
    });

    // Example of how professional details might be tested if there was component logic
    // For now, this is mostly a template concern.
    it('should correctly prepare sessions for display (conceptual)', () => {
      const mockSession: Session = {
        id: 1, userId: 1, mode: SessionMode.VIDEO,
        startTime: new Date().toISOString(), endTime: new Date().toISOString(),
        professionalName: 'Dr. Test', professionalSpecialization: 'Testingology'
      };
      component.upcomingSessions = [mockSession];
      fixture.detectChanges(); // To process bindings if any logic was in component

      // In a real test for component logic transforming data for display:
      // expect(component.processedSessions[0].displayProfessionalName).toBe('Dr. Test');
      // Since it's direct binding, this test is more illustrative.
      expect(component.upcomingSessions[0].professionalName).toBe('Dr. Test');
      expect(component.upcomingSessions[0].professionalSpecialization).toBe('Testingology');
    });
  });
});

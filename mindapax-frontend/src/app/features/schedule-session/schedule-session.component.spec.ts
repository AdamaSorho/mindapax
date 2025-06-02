import { ComponentFixture, TestBed, fakeAsync, tick } from '@angular/core/testing';
import { ReactiveFormsModule } from '@angular/forms';
import { RouterTestingModule } from '@angular/router/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';

import { ScheduleSessionComponent } from './schedule-session.component';
import { SessionService, ScheduleSessionPayload } from '../../services/session.service';
import { UserService } from '../../services/user.service';
import { User } from '../../models/user.model';
import { Session } from '../../models/session.model';
import { SessionMode } from '../../models/enums/SessionFilter';
import { Role } from '../../models/enums/role';
import { HttpErrorResponse } from '@angular/common/http';

describe('ScheduleSessionComponent', () => {
  let component: ScheduleSessionComponent;
  let fixture: ComponentFixture<ScheduleSessionComponent>;
  let mockSessionService: jasmine.SpyObj<SessionService>;
  let mockUserService: jasmine.SpyObj<UserService>;
  // No need to mock Router for these tests unless navigation is explicitly tested

  const mockUsers: User[] = [
    { id: 1, firstName: 'Test', lastName: 'UserA', email: 'a@test.com', role: Role.USER, avatar: '', phone: '', location: '' },
    { id: 2, firstName: 'Another', lastName: 'UserB', email: 'b@test.com', role: Role.USER, avatar: '', phone: '', location: '' },
  ];

  beforeEach(async () => {
    mockSessionService = jasmine.createSpyObj('SessionService', ['scheduleSessionByProfessional']);
    mockUserService = jasmine.createSpyObj('UserService', ['getUsers']);

    await TestBed.configureTestingModule({
      imports: [
        ReactiveFormsModule,
        RouterTestingModule, // For routerLink directives if any, and Router service
        HttpClientTestingModule, // UserService might still inject HttpClient directly if not mocked at a higher level
        ScheduleSessionComponent // Import the standalone component
      ],
      // No need to declare ScheduleSessionComponent if it's standalone and imported
      providers: [
        { provide: SessionService, useValue: mockSessionService },
        { provide: UserService, useValue: mockUserService },
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(ScheduleSessionComponent);
    component = fixture.componentInstance;
    mockUserService.getUsers.and.returnValue(of(mockUsers)); // Default mock for getUsers
    fixture.detectChanges(); // Trigger ngOnInit
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize the form with default values and validators', () => {
    expect(component.scheduleForm).toBeDefined();
    expect(component.scheduleForm.get('userId')?.value).toBe('');
    expect(component.scheduleForm.get('mode')?.value).toBe(SessionMode.VIDEO); // Default value
    expect(component.scheduleForm.get('userId')?.hasValidator(jasmine.any(Function))).toBeTruthy(); // Checks if a validator exists
    // Add more checks for other controls if needed
  });

  it('should load users on initialization', () => {
    expect(mockUserService.getUsers).toHaveBeenCalled();
    expect(component.users.length).toBe(2);
    expect(component.users).toEqual(mockUsers);
  });
  
  it('should display error message if loading users fails', () => {
    const errorResponse = new HttpErrorResponse({ error: 'test error', status: 500, statusText: 'Server Error' });
    mockUserService.getUsers.and.returnValue(throwError(() => errorResponse));
    component.ngOnInit(); // re-call ngOnInit to simulate error on load
    fixture.detectChanges();
    expect(component.errorMessage).toContain('Failed to load users');
  });


  it('should call sessionService.scheduleSessionByProfessional on valid form submission', fakeAsync(() => {
    const mockScheduledSession: Session = {
      id: 1, userId: 1, startTime: new Date().toISOString(), endTime: new Date().toISOString(), mode: SessionMode.VIDEO,
      professionalId: 1, professionalName: 'Dr. Prof', professionalSpecialization: 'Testing'
    };
    mockSessionService.scheduleSessionByProfessional.and.returnValue(of(mockScheduledSession));

    component.scheduleForm.setValue({
      userId: '1',
      startTime: '2024-01-01T10:00', // Valid datetime-local string
      endTime: '2024-01-01T11:00',
      mode: SessionMode.VIDEO,
      notes: 'Test notes'
    });

    component.onSubmit();
    tick(); // Simulate passage of time for async operations like Observables

    const expectedPayload: ScheduleSessionPayload = {
      userId: 1,
      startTime: new Date('2024-01-01T10:00').toISOString(),
      endTime: new Date('2024-01-01T11:00').toISOString(),
      mode: SessionMode.VIDEO,
      notes: 'Test notes'
    };
    expect(mockSessionService.scheduleSessionByProfessional).toHaveBeenCalledWith(expectedPayload);
    expect(component.successMessage).toContain('Session scheduled successfully');
  }));
  
  it('should set error message if end time is not after start time', () => {
    component.scheduleForm.setValue({
      userId: '1',
      startTime: '2024-01-01T11:00',
      endTime: '2024-01-01T10:00', // End time before start time
      mode: SessionMode.VIDEO,
      notes: ''
    });
    component.onSubmit();
    expect(component.errorMessage).toBe('End time must be after start time.');
    expect(mockSessionService.scheduleSessionByProfessional).not.toHaveBeenCalled();
  });


  it('should display an error message if the form is invalid on submit', () => {
    component.scheduleForm.get('userId')?.setValue(''); // Make form invalid
    component.onSubmit();
    expect(component.errorMessage).toBe('Please fill in all required fields.');
    expect(mockSessionService.scheduleSessionByProfessional).not.toHaveBeenCalled();
  });

  it('should display an error message on sessionService.scheduleSessionByProfessional error', fakeAsync(() => {
    const errorResponse = new HttpErrorResponse({ error: {message: 'Scheduling conflict'}, status: 400, statusText: 'Bad Request' });
    mockSessionService.scheduleSessionByProfessional.and.returnValue(throwError(() => errorResponse));
    
    component.scheduleForm.setValue({
      userId: '1',
      startTime: '2024-01-01T10:00',
      endTime: '2024-01-01T11:00',
      mode: SessionMode.VIDEO,
      notes: 'Test notes'
    });

    component.onSubmit();
    tick();

    expect(mockSessionService.scheduleSessionByProfessional).toHaveBeenCalled();
    expect(component.errorMessage).toContain('Failed to schedule session: Scheduling conflict');
  }));
  
   it('should display a generic error message if error.error.message is not available', fakeAsync(() => {
    const errorResponse = new HttpErrorResponse({ status: 500, statusText: 'Internal Server Error' });
    mockSessionService.scheduleSessionByProfessional.and.returnValue(throwError(() => errorResponse));

    component.scheduleForm.setValue({
      userId: '1',
      startTime: '2024-01-01T10:00',
      endTime: '2024-01-01T11:00',
      mode: SessionMode.VIDEO,
      notes: 'Test notes'
    });

    component.onSubmit();
    tick();

    expect(component.errorMessage).toBe('Failed to schedule session: Internal Server Error');
  }));

});

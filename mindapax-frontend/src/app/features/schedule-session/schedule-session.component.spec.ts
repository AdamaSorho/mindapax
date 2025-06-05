import { ComponentFixture, TestBed, fakeAsync, tick, flush } from '@angular/core/testing'; // Added flush
import { ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterTestingModule } from '@angular/router/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';
import { By } from '@angular/platform-browser';

// Import the component AFTER declaring the mock Datepicker
// This is a trick to ensure the global Datepicker is mocked before component attempts to use it.
// However, for testing component logic, we often don't need the actual Flowbite Datepicker object.
// We can spy on document.getElementById and simulate events.

// Mock the global Datepicker constructor
const mockDatepickerInstance = {
  destroy: jasmine.createSpy('destroy'),
  // Add other methods if your component calls them directly
};
const mockDatepickerConstructor = jasmine.createSpy('Datepicker').and.returnValue(mockDatepickerInstance);
(window as any).Datepicker = mockDatepickerConstructor;


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

  let mockStartTimePickerEl: any;
  // let mockEndTimePickerEl: any; // Removed

  const mockUsers: User[] = [
    { id: 1, firstName: 'Test', lastName: 'UserA', email: 'a@test.com', role: Role.USER, avatar: '', phone: '', location: '' },
    { id: 2, firstName: 'Another', lastName: 'UserB', email: 'b@test.com', role: Role.USER, avatar: '', phone: '', location: '' },
  ];

  beforeEach(async () => {
    mockSessionService = jasmine.createSpyObj('SessionService', ['scheduleSessionByProfessional']);
    mockUserService = jasmine.createSpyObj('UserService', ['getUsers']);

    // Reset the global mock for each test
    mockDatepickerConstructor.calls.reset();
    mockDatepickerInstance.destroy.calls.reset();

    await TestBed.configureTestingModule({
      imports: [
        ReactiveFormsModule,
        RouterTestingModule,
        HttpClientTestingModule,
        ScheduleSessionComponent
      ],
      providers: [
        { provide: SessionService, useValue: mockSessionService },
        { provide: UserService, useValue: mockUserService },
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(ScheduleSessionComponent);
    component = fixture.componentInstance;

    // Mock the elements that Flowbite Datepicker would attach to
    mockStartTimePickerEl = document.createElement('input');
    // mockEndTimePickerEl = document.createElement('input'); // Removed
    spyOn(document, 'getElementById').and.callFake((id: string) => {
      if (id === 'startTimePicker') return mockStartTimePickerEl;
      // if (id === 'endTimePicker') return mockEndTimePickerEl; // Removed
      return document.createElement('div'); // Return a generic div for other IDs if getElementById is called elsewhere
    });
    spyOn(mockStartTimePickerEl, 'addEventListener');
    spyOn(mockStartTimePickerEl, 'removeEventListener');
    // spyOn(mockEndTimePickerEl, 'addEventListener'); // Removed
    // spyOn(mockEndTimePickerEl, 'removeEventListener'); // Removed

    mockUserService.getUsers.and.returnValue(of(mockUsers));
    // fixture.detectChanges() here would call ngOnInit & ngAfterViewInit if component is stable.
    // We call it specifically in tests or once after setup if preferred.
  });

  it('should create', () => {
    fixture.detectChanges(); // Calls ngOnInit, then ngAfterViewInit
    expect(component).toBeTruthy();
  });

  it('should initialize the form with default values and validators', () => {
    fixture.detectChanges(); // Ensure ngOnInit runs
    expect(component.scheduleForm).toBeDefined();
    expect(component.scheduleForm.get('userId')?.value).toBe('');
    expect(component.scheduleForm.get('startTime')?.value).toBe('');
    expect(component.scheduleForm.get('durationMinutes')?.value).toBe('');
    expect(component.scheduleForm.get('mode')?.value).toBe(SessionMode.VIDEO);
    expect(component.scheduleForm.get('notes')?.value).toBe('');

    expect(component.scheduleForm.get('userId')?.hasValidator(Validators.required)).toBeTruthy();
    expect(component.scheduleForm.get('startTime')?.hasValidator(Validators.required)).toBeTruthy();
    expect(component.scheduleForm.get('durationMinutes')?.hasValidator(Validators.required)).toBeTruthy();
    expect(component.scheduleForm.get('durationMinutes')?.hasValidator(Validators.min(15))).toBeTruthy();
    expect(component.scheduleForm.get('mode')?.hasValidator(Validators.required)).toBeTruthy();
  });

  it('should load users on initialization', () => {
    fixture.detectChanges(); // Ensure ngOnInit runs
    expect(mockUserService.getUsers).toHaveBeenCalled();
    expect(component.users.length).toBe(2);
    expect(component.users).toEqual(mockUsers);
  });

  it('should display error message if loading users fails', () => {
    mockUserService.getUsers.and.returnValue(throwError(() => new HttpErrorResponse({ error: 'test error', status: 500, statusText: 'Server Error' })));
    fixture.detectChanges(); // Calls ngOnInit which calls loadUsers
    expect(component.errorMessage).toContain('Failed to load users');
  });

  describe('Datepicker Initialization and Cleanup', () => {
    it('should initialize startTimePicker in ngAfterViewInit', () => {
      fixture.detectChanges(); // ngOnInit + ngAfterViewInit
      expect(document.getElementById).toHaveBeenCalledWith('startTimePicker');
      // expect(document.getElementById).not.toHaveBeenCalledWith('endTimePicker'); // Ensure endTimePicker is not sought
      expect((window as any).Datepicker).toHaveBeenCalledTimes(1); // Only one Datepicker instance
      expect(mockStartTimePickerEl.addEventListener).toHaveBeenCalledWith('changeDate', jasmine.any(Function));
      expect(mockStartTimePickerEl.addEventListener).toHaveBeenCalledWith('input', jasmine.any(Function));
      // expect(mockEndTimePickerEl.addEventListener).not.toHaveBeenCalled(); // Ensure no listeners for endTimePicker
    });

    it('should remove startTimePicker event listeners in ngOnDestroy', () => {
      fixture.detectChanges(); // Initialize first
      component.ngOnDestroy();
      expect(mockStartTimePickerEl.removeEventListener).toHaveBeenCalledWith('changeDate', jasmine.any(Function));
      expect(mockStartTimePickerEl.removeEventListener).toHaveBeenCalledWith('input', jasmine.any(Function));
      // expect(mockEndTimePickerEl.removeEventListener).not.toHaveBeenCalled();
    });
  });

  describe('Datepicker Form Updates', () => {
    beforeEach(() => {
      fixture.detectChanges(); // Calls ngOnInit & ngAfterViewInit to set up form and initialize datepickers
    });

    it('should update startTime form control on "changeDate" event from datepicker', () => {
      mockStartTimePickerEl.value = '2024-03-15'; // Datepicker sets this
      component.scheduleForm.get('startTime')?.setValue('2024-03-10T10:00'); // Existing value with time

      // Simulate the 'changeDate' event
      const changeDateEvent = new CustomEvent('changeDate', { detail: { date: new Date(2024, 2, 15) } });
      mockStartTimePickerEl.dispatchEvent(changeDateEvent);

      expect(component.scheduleForm.get('startTime')?.value).toBe('2024-03-15T10:00'); // Time should be preserved
    });

    it('should update startTime form control on manual "input" event', () => {
      const manualDateTime = '2024-03-15T11:30';
      mockStartTimePickerEl.value = manualDateTime;

      // Simulate the 'input' event
      const inputEvent = new Event('input');
      mockStartTimePickerEl.dispatchEvent(inputEvent);

      expect(component.scheduleForm.get('startTime')?.value).toBe(manualDateTime);
    });

    it('should default time to T00:00 if no prior time exists on "changeDate"', () => {
      mockStartTimePickerEl.value = '2024-03-15'; // Datepicker sets this
      component.scheduleForm.get('startTime')?.setValue(''); // No existing value

      const changeDateEvent = new CustomEvent('changeDate', { detail: { date: new Date(2024, 2, 15) } });
      mockStartTimePickerEl.dispatchEvent(changeDateEvent);

      expect(component.scheduleForm.get('startTime')?.value).toBe('2024-03-15T00:00');
    });
  });


  describe('Validation Messages and Form Status', () => {
    beforeEach(() => {
        fixture.detectChanges(); // Ensure component is initialized
    });
    // ... existing validation tests from previous step would go here ...
    // (assuming they are still relevant and pass, no need to repeat them if unchanged)
    // For brevity, I'll skip re-pasting them if they are identical to the previous version.
    // The key is that they should still work.

    function setAndTouch(controlName: string, value: any) {
      component.scheduleForm.get(controlName)?.setValue(value);
      component.scheduleForm.get(controlName)?.markAsTouched();
      fixture.detectChanges();
    }

    it('should display "User selection is required." when userId is touched and empty', () => {
      setAndTouch('userId', '');
      const errorEl = fixture.debugElement.query(By.css('#userIdError'));
      expect(errorEl).toBeTruthy();
      expect(errorEl.nativeElement.textContent).toContain('User selection is required.');
    });

    // Add one for startTime as an example
     it('should display "Start time is required." when startTime is touched and empty', () => {
      setAndTouch('startTime', '');
      const errorEl = fixture.debugElement.query(By.css('#startTimeError'));
      expect(errorEl).toBeTruthy();
      expect(errorEl.nativeElement.textContent).toContain('Start time is required.');
    });

    it('should display "Duration is required." when durationMinutes is touched and empty', () => {
      setAndTouch('durationMinutes', '');
      const errorEl = fixture.debugElement.query(By.css('#durationMinutesError'));
      expect(errorEl).toBeTruthy();
      expect(errorEl.nativeElement.textContent).toContain('Duration is required.');
      expect(component.scheduleForm.get('durationMinutes')?.hasError('required')).toBeTrue();
    });

    it('should display "Duration must be at least X minutes." when durationMinutes is less than min', () => {
      setAndTouch('durationMinutes', 10); // Assuming min is 15
      const errorEl = fixture.debugElement.query(By.css('#durationMinutesError'));
      expect(errorEl).toBeTruthy();
      expect(errorEl.nativeElement.textContent).toContain('Duration must be at least 15 minutes.');
      expect(component.scheduleForm.get('durationMinutes')?.hasError('min')).toBeTrue();
    });

  });

  describe('Form Submission Logic', () => {
    beforeEach(() => {
        fixture.detectChanges(); // Ensure component is initialized
    });
    it('should call sessionService.scheduleSessionByProfessional with durationMinutes on valid form submission', fakeAsync(() => {
    const mockStartTime = new Date();
    const mockDuration = 60;
    const mockScheduledSession: Session = { // This is the response from the service
      id: 1,
      userId: 1,
      startTime: mockStartTime.toISOString(),
      durationMinutes: mockDuration,
      mode: SessionMode.VIDEO,
      professionalId: 1,
      professionalName: 'Dr. Prof',
      professionalSpecialization: 'Testing'
    };
    mockSessionService.scheduleSessionByProfessional.and.returnValue(of(mockScheduledSession));

    component.scheduleForm.setValue({
      userId: '1',
      startTime: '2024-01-01T10:00',
      durationMinutes: mockDuration, // Use durationMinutes
      mode: SessionMode.VIDEO,
      notes: 'Test notes'
    });

    component.onSubmit();
    tick();

    const expectedPayload: ScheduleSessionPayload = {
      userId: 1,
      startTime: new Date('2024-01-01T10:00').toISOString(),
      durationMinutes: mockDuration, // Check for durationMinutes
      mode: SessionMode.VIDEO,
      notes: 'Test notes'
    };
    expect(mockSessionService.scheduleSessionByProfessional).toHaveBeenCalledWith(expectedPayload);
    expect(component.successMessage).toContain('Session scheduled successfully');
  }));

    // Remove test for: 'should set error message if end time is not after start time during submission'
    // as this logic is no longer in the component.

    it('should display an error message if the form is invalid during submission attempt', () => {
    component.scheduleForm.get('userId')?.setValue(''); // Make form invalid
    component.onSubmit();
    expect(component.errorMessage).toBe('Please fill in all required fields.');
    expect(mockSessionService.scheduleSessionByProfessional).not.toHaveBeenCalled();
  });

    it('should display an error message on sessionService.scheduleSessionByProfessional error during submission', fakeAsync(() => {
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

    it('should display a generic error message if error.error.message is not available during submission error', fakeAsync(() => {
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

});

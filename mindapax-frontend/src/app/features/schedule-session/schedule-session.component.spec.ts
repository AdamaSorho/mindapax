import { ComponentFixture, TestBed, fakeAsync, tick } from '@angular/core/testing';
import { ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterTestingModule } from '@angular/router/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';
import { By } from '@angular/platform-browser';
import { HttpErrorResponse } from '@angular/common/http';

// Mock the global Datepicker constructor before component import
const mockDatepickerInstance = {
  destroy: jasmine.createSpy('destroy'),
  // Mock other methods if your component calls them e.g. getDate(), setDate()
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

describe('ScheduleSessionComponent', () => {
  let component: ScheduleSessionComponent;
  let fixture: ComponentFixture<ScheduleSessionComponent>;
  let mockSessionService: jasmine.SpyObj<SessionService>;
  let mockUserService: jasmine.SpyObj<UserService>;

  let mockStartDatePickerEl: any; // For the date part of startTime

  const mockUsers: User[] = [
    { id: 1, firstName: 'Test', lastName: 'UserA', email: 'a@test.com', role: Role.USER, avatar: '', phone: '', location: '' },
    { id: 2, firstName: 'Another', lastName: 'UserB', email: 'b@test.com', role: Role.USER, avatar: '', phone: '', location: '' },
  ];

  beforeEach(async () => {
    mockSessionService = jasmine.createSpyObj('SessionService', ['scheduleSessionByProfessional']);
    mockUserService = jasmine.createSpyObj('UserService', ['getUsers']);

    mockDatepickerConstructor.calls.reset();
    mockDatepickerInstance.destroy.calls.reset();

    await TestBed.configureTestingModule({
      imports: [
        ReactiveFormsModule,
        RouterTestingModule,
        HttpClientTestingModule,
        ScheduleSessionComponent // Assuming it's a standalone component
      ],
      providers: [
        { provide: SessionService, useValue: mockSessionService },
        { provide: UserService, useValue: mockUserService },
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(ScheduleSessionComponent);
    component = fixture.componentInstance;

    mockStartDatePickerEl = document.createElement('input');
    spyOn(document, 'getElementById').and.callFake((id: string) => {
      if (id === 'startDatePicker') return mockStartDatePickerEl;
      // Return a generic div for other potential getElementById calls to prevent null errors
      return document.createElement('div');
    });
    spyOn(mockStartDatePickerEl, 'addEventListener');
    spyOn(mockStartDatePickerEl, 'removeEventListener');

    mockUserService.getUsers.and.returnValue(of(mockUsers));
    // fixture.detectChanges() will be called in individual tests or describe blocks
  });

  it('should create', () => {
    fixture.detectChanges(); // Calls ngOnInit, then ngAfterViewInit
    expect(component).toBeTruthy();
  });

  it('should initialize the form with default values and validators', () => {
    fixture.detectChanges(); // Ensure ngOnInit runs
    expect(component.scheduleForm).toBeDefined();
    expect(component.scheduleForm.get('userId')?.value).toBe('');
    expect(component.scheduleForm.get('startDate')?.value).toBe('');
    expect(component.scheduleForm.get('startTimeValue')?.value).toBe('');
    expect(component.scheduleForm.get('durationMinutes')?.value).toBe('');
    expect(component.scheduleForm.get('mode')?.value).toBe(SessionMode.VIDEO);
    expect(component.scheduleForm.get('notes')?.value).toBe('');

    expect(component.scheduleForm.get('userId')?.hasValidator(Validators.required)).toBeTruthy();
    expect(component.scheduleForm.get('startDate')?.hasValidator(Validators.required)).toBeTruthy();
    expect(component.scheduleForm.get('startTimeValue')?.hasValidator(Validators.required)).toBeTruthy();
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
    fixture.detectChanges();
    expect(component.errorMessage).toContain('Failed to load users');
  });

  describe('Datepicker Initialization and Cleanup', () => {
    it('should initialize startDatePicker in ngAfterViewInit', () => {
      fixture.detectChanges();
      expect(document.getElementById).toHaveBeenCalledWith('startDatePicker');
      expect((window as any).Datepicker).toHaveBeenCalledTimes(1);
      expect(mockStartDatePickerEl.addEventListener).toHaveBeenCalledWith('changeDate', jasmine.any(Function));
    });

    it('should remove startDatePicker event listeners in ngOnDestroy', () => {
      fixture.detectChanges();
      component.ngOnDestroy();
      expect(mockStartDatePickerEl.removeEventListener).toHaveBeenCalledWith('changeDate', jasmine.any(Function));
    });
  });

  describe('Datepicker Form Updates for startDate', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    it('should update startDate form control on "changeDate" event from datepicker', () => {
      mockStartDatePickerEl.value = '2024-03-15'; // Flowbite Datepicker updates the input value

      // Get the actual listener function attached by the component
      const changeDateListener = mockStartDatePickerEl.addEventListener.calls.argsFor(0)[1];
      changeDateListener(new CustomEvent('changeDate', { detail: { date: new Date(2024, 2, 15) } })); // Dispatch event

      expect(component.scheduleForm.get('startDate')?.value).toBe('2024-03-15');
    });
  });

  describe('Validation Messages and Form Status', () => {
    beforeEach(() => {
        fixture.detectChanges();
    });

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

     it('should display "Start date is required." when startDate is touched and empty', () => {
      setAndTouch('startDate', '');
      const errorEl = fixture.debugElement.query(By.css('#startDateError'));
      expect(errorEl).toBeTruthy();
      expect(errorEl.nativeElement.textContent).toContain('Start date is required.');
    });

     it('should display "Start time is required." when startTimeValue is touched and empty', () => {
      setAndTouch('startTimeValue', '');
      const errorEl = fixture.debugElement.query(By.css('#startTimeValueError'));
      expect(errorEl).toBeTruthy();
      expect(errorEl.nativeElement.textContent).toContain('Start time is required.');
    });

    it('should display "Duration is required." when durationMinutes is touched and empty', () => {
      setAndTouch('durationMinutes', '');
      const errorEl = fixture.debugElement.query(By.css('#durationMinutesError'));
      expect(errorEl).toBeTruthy();
      expect(errorEl.nativeElement.textContent).toContain('Duration is required.');
    });

    it('should display "Duration must be at least X minutes." when durationMinutes is less than min', () => {
      setAndTouch('durationMinutes', 10); // Assuming min is 15
      const errorEl = fixture.debugElement.query(By.css('#durationMinutesError'));
      expect(errorEl).toBeTruthy();
      expect(errorEl.nativeElement.textContent).toContain('Duration must be at least 15 minutes.');
    });
  });

  describe('Form Submission Logic', () => {
    beforeEach(() => {
        fixture.detectChanges();
    });

    it('should call sessionService.scheduleSessionByProfessional with combined startTime on valid form submission', fakeAsync(() => {
      const mockDate = '2024-05-15';
      const mockTime = '10:30';
      const mockDuration = 60;
      const combinedDateTimeString = `${mockDate}T${mockTime}`;
      const expectedStartTimeISO = new Date(combinedDateTimeString).toISOString();

      const mockReturnedSession: Session = {
        id: 1, userId: 1, startTime: expectedStartTimeISO, durationMinutes: mockDuration, mode: SessionMode.VIDEO,
        professionalId: 1, professionalName: 'Dr. P', professionalSpecialization: 'Psy'
      };
      mockSessionService.scheduleSessionByProfessional.and.returnValue(of(mockReturnedSession));

      component.scheduleForm.setValue({
        userId: '1',
        startDate: mockDate,
        startTimeValue: mockTime,
        durationMinutes: mockDuration,
        mode: SessionMode.VIDEO,
        notes: 'Test notes'
      });

      component.onSubmit();
      tick();

      const expectedPayload: ScheduleSessionPayload = {
        userId: 1,
        startTime: expectedStartTimeISO,
        durationMinutes: mockDuration,
        mode: SessionMode.VIDEO,
        notes: 'Test notes'
      };
      expect(mockSessionService.scheduleSessionByProfessional).toHaveBeenCalledWith(expectedPayload);
      expect(component.successMessage).toContain('Session scheduled successfully');
    }));

    it('should show error if startDate or startTimeValue is missing on submit', () => {
      component.scheduleForm.patchValue({
        userId: '1',
        // startDate: '', // Missing startDate
        startTimeValue: '10:00',
        durationMinutes: 60,
        mode: SessionMode.VIDEO
      });
      component.onSubmit();
      expect(component.errorMessage).toBe('Start date or start time is missing.');
      expect(mockSessionService.scheduleSessionByProfessional).not.toHaveBeenCalled();

      component.scheduleForm.patchValue({ startDate: '2024-01-01', startTimeValue: '' });
      component.onSubmit();
      expect(component.errorMessage).toBe('Start date or start time is missing.');
      expect(mockSessionService.scheduleSessionByProfessional).not.toHaveBeenCalled();
    });

    it('should show error if combined date-time is invalid on submit', () => {
        component.scheduleForm.setValue({
            userId: '1',
            startDate: 'invalid-date', // Invalid date part
            startTimeValue: '10:00',
            durationMinutes: 60,
            mode: SessionMode.VIDEO,
            notes: 'Test'
        });
        component.onSubmit();
        expect(component.errorMessage).toBe('Invalid start date or time format.');
        expect(mockSessionService.scheduleSessionByProfessional).not.toHaveBeenCalled();
    });

    it('should display an error message if the form is invalid during submission attempt', () => {
        component.scheduleForm.get('userId')?.setValue(''); // Make form invalid (e.g. userId)
        component.onSubmit();
        expect(component.errorMessage).toBe('Please fill in all required fields.');
        expect(mockSessionService.scheduleSessionByProfessional).not.toHaveBeenCalled();
    });

    it('should display an error message on sessionService.scheduleSessionByProfessional error during submission', fakeAsync(() => {
        const errorResponse = new HttpErrorResponse({ error: {message: 'Scheduling conflict'}, status: 400, statusText: 'Bad Request' });
        mockSessionService.scheduleSessionByProfessional.and.returnValue(throwError(() => errorResponse));

        component.scheduleForm.setValue({
          userId: '1',
          startDate: '2024-01-01',
          startTimeValue: '10:00',
          durationMinutes: 60,
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
          startDate: '2024-01-01',
          startTimeValue: '10:00',
          durationMinutes: 60,
          mode: SessionMode.VIDEO,
          notes: 'Test notes'
        });

        component.onSubmit();
        tick();

        expect(component.errorMessage).toBe('Failed to schedule session: Internal Server Error');
    }));
  });
});

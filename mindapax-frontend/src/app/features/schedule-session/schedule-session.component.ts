import { Component, OnInit, AfterViewInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { SessionService, ScheduleSessionPayload } from '../../services/session.service';
import { UserService } from '../../services/user.service';
import { User } from '../../models/user.model';
import { SessionMode } from '../../models/enums/SessionFilter';
import { HttpErrorResponse } from '@angular/common/http';

// If you have specific types for Flowbite's Datepicker:
// import { Datepicker, DatepickerOptions, DatepickerInterface } from 'flowbite-datepicker';
// Otherwise, declare it to inform TypeScript that it's a global variable:
declare var Datepicker: any;
declare var initFlowbite: any; // If you were to use global init

@Component({
  selector: 'app-schedule-session',
  templateUrl: './schedule-session.component.html',
  styleUrls: ['./schedule-session.component.css']
})
export class ScheduleSessionComponent implements OnInit, AfterViewInit, OnDestroy {
  scheduleForm!: FormGroup;
  users: User[] = [];
  sessionModes = Object.values(SessionMode);
  errorMessage: string | null = null;
  successMessage: string | null = null;

  private startTimepickerInstance: any;
  // No endTimepickerInstance needed
  // private endTimepickerInstance: any;

  // Store event listener functions to remove them correctly
  private startTimeChangeDateListener!: (event: any) => void;
  private startTimeInputListener!: (event: any) => void;
  // No endTime listeners needed
  // private endTimeChangeDateListener!: (event: any) => void;
  // private endTimeInputListener!: (event: any) => void;


  constructor(
    private fb: FormBuilder,
    private sessionService: SessionService,
    private userService: UserService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.scheduleForm = this.fb.group({
      userId: ['', Validators.required],
      // Store as full ISO-like string (YYYY-MM-DDTHH:mm)
      // The datepicker will manage the date part, time is manual.
      startTime: ['', Validators.required],
      durationMinutes: ['', [Validators.required, Validators.min(15)]], // Added durationMinutes
      mode: [SessionMode.VIDEO, Validators.required],
      notes: ['']
    });

    this.loadUsers();
  }

  ngAfterViewInit(): void {
    this.initDatepickers(); // Only initializes startTimePicker now
  }

  ngOnDestroy(): void {
    // Remove event listeners to prevent memory leaks
    const startTimePickerEl = document.getElementById('startTimePicker');
    if (startTimePickerEl) {
      if (this.startTimeChangeDateListener) {
        startTimePickerEl.removeEventListener('changeDate', this.startTimeChangeDateListener);
      }
      if (this.startTimeInputListener) {
        startTimePickerEl.removeEventListener('input', this.startTimeInputListener);
      }
    }
    // No endTimePicker related cleanup
  }

  private initDatepickers(): void {
    const startTimePickerEl = document.getElementById('startTimePicker') as HTMLInputElement | null;
    // const endTimePickerEl = document.getElementById('endTimePicker') as HTMLInputElement | null; // Removed

    // Options for Flowbite Datepicker
    // Note: Flowbite's datepicker is primarily for dates. Time needs manual input.
    // The format 'yyyy-mm-dd' applies to how the datepicker displays/parses the date part.
    const datepickerOptions = { // Renamed from commonOptions for clarity
      autohide: true,
      format: 'yyyy-mm-dd',
      todayHighlight: true,
    };

    if (startTimePickerEl) {
      this.startTimepickerInstance = new Datepicker(startTimePickerEl, { ...datepickerOptions });

      this.startTimeChangeDateListener = (event: CustomEvent) => {
        const newDateValue = startTimePickerEl.value;
        const existingFormControlValue = this.scheduleForm.get('startTime')?.value || "";
        let timePart = "00:00";
        if (existingFormControlValue && existingFormControlValue.includes('T')) {
            timePart = existingFormControlValue.split('T')[1] || "00:00";
        }
        this.scheduleForm.get('startTime')?.setValue(`${newDateValue}T${timePart}`);
        this.scheduleForm.get('startTime')?.markAsDirty();
      };
      startTimePickerEl.addEventListener('changeDate', this.startTimeChangeDateListener);

      this.startTimeInputListener = (event: Event) => {
        const manualValue = (event.target as HTMLInputElement).value;
        this.scheduleForm.get('startTime')?.setValue(manualValue);
        this.scheduleForm.get('startTime')?.markAsDirty();
      };
      startTimePickerEl.addEventListener('input', this.startTimeInputListener);
    }

    // No endTimePicker initialization
  }

  loadUsers(): void {
    this.userService.getUsers().subscribe({
      next: (users) => {
        this.users = users;
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = 'Failed to load users: ' + error.message;
        console.error('Error loading users:', error);
      }
    });
  }

  onSubmit(): void {
    this.errorMessage = null;
    this.successMessage = null;

    if (this.scheduleForm.invalid) {
      this.errorMessage = 'Please fill in all required fields.';
      return;
    }

    const formValues = this.scheduleForm.value;

    // startTime is already expected to be "YYYY-MM-DDTHH:mm" from input/datepicker logic
    // No need to parse endTime anymore
    const startTimeISO = new Date(formValues.startTime).toISOString();
    // const endTimeISO = new Date(formValues.endTime).toISOString(); // REMOVE

    // Remove validation for endTime vs startTime
    // if (new Date(endTimeISO) <= new Date(startTimeISO)) {
    //   this.errorMessage = 'End time must be after start time.';
    //   return;
    // }

    const payload: ScheduleSessionPayload = {
      userId: Number(formValues.userId),
      startTime: startTimeISO,
      durationMinutes: Number(formValues.durationMinutes), // ADD durationMinutes
      mode: formValues.mode,
      notes: formValues.notes
    };

    this.sessionService.scheduleSessionByProfessional(payload).subscribe({
      next: (createdSession) => {
        this.successMessage = `Session scheduled successfully with ID: ${createdSession.id}`;
        this.scheduleForm.reset({ mode: SessionMode.VIDEO }); // Reset form with default mode
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = 'Failed to schedule session: ' + (error.error?.message || error.message);
        console.error('Error scheduling session:', error);
      }
    });
  }
}

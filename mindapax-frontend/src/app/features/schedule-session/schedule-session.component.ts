import { Component, OnInit, AfterViewInit, OnDestroy } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { Router } from '@angular/router';
import {
  SessionService,
  ScheduleSessionPayload,
} from '../../services/session.service';
import { UserService } from '../../services/user.service';
import { User } from '../../models/user.model';
import { SessionMode } from '../../models/enums/SessionFilter';
import { HttpErrorResponse } from '@angular/common/http';
import { CommonModule } from '@angular/common';

// If you have specific types for Flowbite's Datepicker:
// import { Datepicker, DatepickerOptions, DatepickerInterface } from 'flowbite-datepicker';
// Otherwise, declare it to inform TypeScript that it's a global variable:
declare var Datepicker: any;
declare var initFlowbite: any; // If you were to use global init

@Component({
  selector: 'app-schedule-session',
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './schedule-session.component.html',
  styleUrl: './schedule-session.component.css',
})
export class ScheduleSessionComponent
  implements OnInit, AfterViewInit, OnDestroy
{
  scheduleForm!: FormGroup;
  users: User[] = [];
  sessionModes = Object.values(SessionMode);
  errorMessage: string | null = null;
  successMessage: string | null = null;

  private startTimepickerInstance: any;
  private endTimepickerInstance: any;

  // Store event listener functions to remove them correctly
  private startTimeChangeDateListener!: (event: any) => void;
  private startTimeInputListener!: (event: any) => void;
  private endTimeChangeDateListener!: (event: any) => void;
  private endTimeInputListener!: (event: any) => void;

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
      endTime: ['', Validators.required],
      mode: [SessionMode.VIDEO, Validators.required],
      notes: [''],
    });

    this.loadUsers();
  }

  ngAfterViewInit(): void {
    // It's possible initFlowbite() needs to be called if data attributes are used for other things
    // and this component is loaded dynamically. For explicit Datepicker, it's not strictly needed.
    // if (typeof initFlowbite !== 'undefined') {
    //   initFlowbite();
    // }
    this.initDatepickers();
  }

  ngOnDestroy(): void {
    // Remove event listeners to prevent memory leaks
    const startTimePickerEl = document.getElementById('startTimePicker');
    if (startTimePickerEl) {
      if (this.startTimeChangeDateListener) {
        startTimePickerEl.removeEventListener(
          'changeDate',
          this.startTimeChangeDateListener
        );
      }
      if (this.startTimeInputListener) {
        startTimePickerEl.removeEventListener(
          'input',
          this.startTimeInputListener
        );
      }
    }

    const endTimePickerEl = document.getElementById('endTimePicker');
    if (endTimePickerEl) {
      if (this.endTimeChangeDateListener) {
        endTimePickerEl.removeEventListener(
          'changeDate',
          this.endTimeChangeDateListener
        );
      }
      if (this.endTimeInputListener) {
        endTimePickerEl.removeEventListener('input', this.endTimeInputListener);
      }
    }

    // If Flowbite Datepicker instances have a destroy method, call it.
    // This depends on the actual Datepicker library Flowbite uses internally.
    // Example:
    // if (this.startTimepickerInstance && typeof this.startTimepickerInstance.destroy === 'function') {
    //   this.startTimepickerInstance.destroy();
    // }
    // if (this.endTimepickerInstance && typeof this.endTimepickerInstance.destroy === 'function') {
    //   this.endTimepickerInstance.destroy();
    // }
  }

  private initDatepickers(): void {
    const startTimePickerEl = document.getElementById(
      'startTimePicker'
    ) as HTMLInputElement | null;
    const endTimePickerEl = document.getElementById(
      'endTimePicker'
    ) as HTMLInputElement | null;

    // Options for Flowbite Datepicker
    // Note: Flowbite's datepicker is primarily for dates. Time needs manual input.
    // The format 'yyyy-mm-dd' applies to how the datepicker displays/parses the date part.
    const commonOptions = {
      autohide: true,
      format: 'yyyy-mm-dd',
      todayHighlight: true,
    };

    if (startTimePickerEl) {
      this.startTimepickerInstance = new Datepicker(startTimePickerEl, {
        ...commonOptions,
      });

      this.startTimeChangeDateListener = (event: CustomEvent) => {
        // event.detail.date is the Date object selected by the datepicker (date part only)
        // The input field (event.target.value or startTimePickerEl.value) will have "yyyy-mm-dd"
        const newDateValue = startTimePickerEl.value; // Date part from picker: "YYYY-MM-DD"
        const existingFormControlValue =
          this.scheduleForm.get('startTime')?.value || '';
        let timePart = '00:00'; // Default time
        if (
          existingFormControlValue &&
          existingFormControlValue.includes('T')
        ) {
          timePart = existingFormControlValue.split('T')[1] || '00:00';
        }

        this.scheduleForm
          .get('startTime')
          ?.setValue(`${newDateValue}T${timePart}`);
        this.scheduleForm.get('startTime')?.markAsDirty();
      };
      startTimePickerEl.addEventListener(
        'changeDate',
        this.startTimeChangeDateListener
      );

      // Listener for manual input changes (e.g., typing time)
      this.startTimeInputListener = (event: Event) => {
        const manualValue = (event.target as HTMLInputElement).value;
        this.scheduleForm.get('startTime')?.setValue(manualValue);
        this.scheduleForm.get('startTime')?.markAsDirty();
      };
      startTimePickerEl.addEventListener('input', this.startTimeInputListener);
    }

    if (endTimePickerEl) {
      this.endTimepickerInstance = new Datepicker(endTimePickerEl, {
        ...commonOptions,
      });

      this.endTimeChangeDateListener = (event: CustomEvent) => {
        const newDateValue = endTimePickerEl.value; // Date part from picker: "YYYY-MM-DD"
        const existingFormControlValue =
          this.scheduleForm.get('endTime')?.value || '';
        let timePart = '00:00'; // Default time
        if (
          existingFormControlValue &&
          existingFormControlValue.includes('T')
        ) {
          timePart = existingFormControlValue.split('T')[1] || '00:00';
        }
        this.scheduleForm
          .get('endTime')
          ?.setValue(`${newDateValue}T${timePart}`);
        this.scheduleForm.get('endTime')?.markAsDirty();
      };
      endTimePickerEl.addEventListener(
        'changeDate',
        this.endTimeChangeDateListener
      );

      this.endTimeInputListener = (event: Event) => {
        const manualValue = (event.target as HTMLInputElement).value;
        this.scheduleForm.get('endTime')?.setValue(manualValue);
        this.scheduleForm.get('endTime')?.markAsDirty();
      };
      endTimePickerEl.addEventListener('input', this.endTimeInputListener);
    }
  }

  loadUsers(): void {
    this.userService.getProfessionalConnectedUsers().subscribe({
      next: (users) => {
        this.users = users;
        console.log('Loaded users:', this.users);
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = 'Failed to load users: ' + error.message;
        console.error('Error loading users:', error);
      },
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

    // Values from form controls are already expected to be "YYYY-MM-DDTHH:mm"
    const startTimeISO = new Date(formValues.startTime).toISOString();
    const endTimeISO = new Date(formValues.endTime).toISOString();

    if (new Date(endTimeISO) <= new Date(startTimeISO)) {
      this.errorMessage = 'End time must be after start time.';
      return;
    }

    const payload: ScheduleSessionPayload = {
      userId: Number(formValues.userId),
      startTime: startTimeISO,
      endTime: endTimeISO,
      mode: formValues.mode,
      notes: formValues.notes,
    };

    this.sessionService.scheduleSessionByProfessional(payload).subscribe({
      next: (createdSession) => {
        this.successMessage = `Session scheduled successfully with ID: ${createdSession.id}`;
        this.scheduleForm.reset({ mode: SessionMode.VIDEO }); // Reset form with default mode
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage =
          'Failed to schedule session: ' +
          (error.error?.message || error.message);
        console.error('Error scheduling session:', error);
      },
    });
  }
}

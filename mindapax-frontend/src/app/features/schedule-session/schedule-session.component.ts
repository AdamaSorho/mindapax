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
import { ToastService } from '../../services/toast.service';

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
  paymentRequired = false;

  constructor(
    private fb: FormBuilder,
    private sessionService: SessionService,
    private userService: UserService,
    private router: Router,
    private toast: ToastService,
  ) {}

  ngOnInit(): void {
    this.scheduleForm = this.fb.group({
      userId: ['', Validators.required],
      startDate: ['', Validators.required], // New
      startTimeValue: ['', Validators.required], // New
      durationMinutes: ['', [Validators.required, Validators.min(15)]],
      mode: [SessionMode.VIDEO, Validators.required], // Default mode
      notes: [''],
    });

    this.loadUsers();
  }

  ngAfterViewInit(): void {
    // this.initDatepickers();
  }

  ngOnDestroy(): void {
    // const startDatePickerEl = document.getElementById('startDatePicker'); // Use new ID
    // if (startDatePickerEl) {
    //   if (this.startDateChangeDateListener) {
    //     startDatePickerEl.removeEventListener(
    //       'changeDate',
    //       this.startDateChangeDateListener
    //     );
    //   }
    //   // No startTimeInputListener to remove if it's not used for the date part
    // }
  }

  // private initDatepickers(): void {
  //   const startDatePickerEl = document.getElementById(
  //     'startDatePicker'
  //   ) as HTMLInputElement | null; // Use new ID

  //   // Options for Flowbite Datepicker
  //   const datepickerOptions = {
  //     autohide: true,
  //     format: 'yyyy-mm-dd',
  //     todayHighlight: true,
  //   };

  //   if (startDatePickerEl) {
  //     // Use new ID
  //     this.startTimepickerInstance = new Datepicker(startDatePickerEl, {
  //       ...datepickerOptions,
  //     }); // Keep instance name for now, or rename

  //     this.startDateChangeDateListener = (event: CustomEvent) => {
  //       // Renamed listener
  //       // Flowbite Datepicker typically provides the selected date directly on the event or via its instance.
  //       // The input's value (startDatePickerEl.value) will be the formatted date string "yyyy-mm-dd".
  //       if (startDatePickerEl.value) {
  //         this.scheduleForm.get('startDate')?.setValue(startDatePickerEl.value);
  //         this.scheduleForm.get('startDate')?.markAsDirty();
  //       }
  //     };
  //     startDatePickerEl.addEventListener(
  //       'changeDate',
  //       this.startDateChangeDateListener
  //     );
  //     // No separate 'input' listener needed for the datepicker text field itself if 'changeDate' is sufficient
  //     // The 'startTimeValue' input (type="time") will handle its own input via formControlName.
  //   }
  // }

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
    const datePart = formValues.startDate; // e.g., "2023-10-27"
    const timePart = formValues.startTimeValue; // e.g., "14:30"

    if (!datePart || !timePart) {
      this.errorMessage = 'Start date or start time is missing.';
      console.error(
        'Start date or start time is missing from form values: ',
        formValues
      );
      return; // Exit if essential parts are missing
    }

    // Combine date and time. HTML input type="time" provides HH:mm.
    const combinedStartTimeString = `${datePart}T${timePart}`; // Format: "YYYY-MM-DDTHH:mm"

    // It's safer to parse this combined string into a Date object to ensure it's valid
    // and then convert to ISO string if the backend strictly needs the 'Z' or offset.
    // If backend handles "YYYY-MM-DDTHH:mm" directly for LocalDateTime, this is fine.
    // For robustness with potential backend expectations of full ISO:
    const startTimeDateObject = new Date(combinedStartTimeString);
    if (isNaN(startTimeDateObject.getTime())) {
      this.errorMessage = 'Invalid start date or time format.';
      console.error(
        'Failed to parse combined date-time: ',
        combinedStartTimeString
      );
      return;
    }
    const startTimeISO = startTimeDateObject.toISOString();

    const payload: ScheduleSessionPayload = {
      userId: Number(formValues.userId),
      startTime: startTimeISO, // Use the combined and then ISO converted string
      durationMinutes: Number(formValues.durationMinutes),
      mode: formValues.mode,
      notes: formValues.notes || '', // Ensure notes is not null
    };

    this.sessionService.scheduleSessionByProfessional(payload).subscribe({
      next: (createdSession) => {
        this.successMessage = `Session scheduled successfully with ID: ${createdSession.id}`;
        this.scheduleForm.reset({ mode: SessionMode.VIDEO }); // Reset form with default mode
        this.router.navigate(['/member/sessions']);
      },
      error: (error: HttpErrorResponse) => {
        console.error('Error scheduling session:', error);
        this.paymentRequired = error.status === 402 ||
          /payment required|no session credits/i.test(error.error?.message || '');
        // Use global toast notifications instead of inline error block
        if (this.paymentRequired) {
          this.toast.error(
            'Client has no active package or session credits.',
            7000,
            [
              { label: 'View packages', route: '/member/packages' },
              { label: 'Go to Billing', route: '/member/billing' },
            ],
          );
        } else {
          this.toast.error('Failed to schedule session: ' + (error.error?.message || error.message));
        }
        this.errorMessage = null;
      },
    });
  }
}

import { Component, OnInit } from '@angular/core';
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
import { SessionMode } from '../../models/enums/SessionFilter'; // Adjust path as needed
import { HttpErrorResponse } from '@angular/common/http';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-schedule-session',
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './schedule-session.component.html',
  styleUrl: './schedule-session.component.css',
})
export class ScheduleSessionComponent implements OnInit {
  scheduleForm!: FormGroup;
  users: User[] = [];
  sessionModes = Object.values(SessionMode); // For dropdown
  errorMessage: string | null = null;
  successMessage: string | null = null;

  constructor(
    private fb: FormBuilder,
    private sessionService: SessionService,
    private userService: UserService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.scheduleForm = this.fb.group({
      userId: ['', Validators.required],
      startTime: ['', Validators.required],
      endTime: ['', Validators.required],
      mode: [SessionMode.VIDEO, Validators.required], // Default to VIDEO
      notes: [''],
    });

    this.loadUsers();
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

    // Convert local datetime-local input to ISO 8601 string format
    const startTime = new Date(formValues.startTime).toISOString();
    const endTime = new Date(formValues.endTime).toISOString();

    if (new Date(endTime) <= new Date(startTime)) {
      this.errorMessage = 'End time must be after start time.';
      return;
    }

    const payload: ScheduleSessionPayload = {
      userId: Number(formValues.userId),
      startTime: startTime,
      endTime: endTime,
      mode: formValues.mode,
      notes: formValues.notes,
    };

    this.sessionService.scheduleSessionByProfessional(payload).subscribe({
      next: (createdSession) => {
        this.successMessage = `Session scheduled successfully with ID: ${createdSession.id}`;
        this.scheduleForm.reset({ mode: SessionMode.VIDEO }); // Reset form with default mode
        // Optionally navigate away or show more detailed success info
        // this.router.navigate(['/sessions']); // Example navigation
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

import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-forgot-password',
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './forgot-password.component.html',
  styleUrl: './forgot-password.component.css',
})
export class ForgotPasswordComponent {
  forgotPasswordForm: FormGroup;
  isSubmitting = false;
  emailSent = false;
  submitError = '';

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService
  ) {
    this.forgotPasswordForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
    });
  }

  onSubmit() {
    if (this.forgotPasswordForm.valid) {
      this.isSubmitting = true;
      this.submitError = '';
      const email = this.forgotPasswordForm.value.email;
      this.authService.requestPasswordReset(email).subscribe({
        next: () => {
          this.isSubmitting = false;
          this.emailSent = true;
        },
        error: (err) => {
          this.isSubmitting = false;
          this.submitError =
            err?.error?.message ||
            'There was a problem with your request. Please try again.';
        },
      });
    } else {
      // Mark all fields as touched to trigger validation messages
      Object.keys(this.forgotPasswordForm.controls).forEach((key) => {
        const control = this.forgotPasswordForm.get(key);
        control?.markAsTouched();
      });
    }
  }

  goToLogin() {
    this.router.navigate(['/auth/login']);
  }
}

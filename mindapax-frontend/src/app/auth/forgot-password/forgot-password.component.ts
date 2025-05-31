import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { Router, RouterModule } from '@angular/router';

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

  constructor(private fb: FormBuilder, private router: Router) {
    this.forgotPasswordForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
    });
  }

  onSubmit() {
    if (this.forgotPasswordForm.valid) {
      this.isSubmitting = true;
      this.submitError = '';

      // Here you would normally make an API call to request a password reset
      console.log('Forgot password submitted:', this.forgotPasswordForm.value);

      // Simulate API call with timeout
      setTimeout(() => {
        this.isSubmitting = false;

        // For demonstration purposes, let's simulate a successful password reset request
        // In a real app, you would check the response from your service
        if (Math.random() > 0.1) {
          // 90% chance of success for demo
          this.emailSent = true;
        } else {
          // Show error message
          this.submitError =
            'There was a problem with your request. Please try again.';
        }
      }, 1000);
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

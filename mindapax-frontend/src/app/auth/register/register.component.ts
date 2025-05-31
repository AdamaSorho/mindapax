import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  ValidationErrors,
  Validators,
} from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { Role } from '../../models/enums/role';
import { specializationOptions } from '../../models/enums/specialization';

@Component({
  selector: 'app-register',
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './register.component.html',
  styleUrl: './register.component.css',
})
export class RegisterComponent implements OnInit {
  registrationForm!: FormGroup;
  isSubmitting = false;
  passwordVisible = false;
  confirmPasswordVisible = false;
  specializationsOptions = specializationOptions;

  // File handling
  certificationFiles: File[] = [];
  resumeFile: File | null = null;
  certificationError: string | null = null;
  resumeError: string | null = null;

  // Max file sizes in bytes
  readonly MAX_CERTIFICATION_SIZE = 5 * 1024 * 1024; // 5MB
  readonly MAX_RESUME_SIZE = 10 * 1024 * 1024; // 10MB

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.initForm();

    // Listen for user type changes to add/remove professional details validation
    this.registrationForm
      .get('userType')
      ?.valueChanges.subscribe((userType) => {
        if (userType === 'professional') {
          this.addProfessionalValidation();
        } else {
          this.removeProfessionalValidation();
        }
      });
  }

  initForm(): void {
    this.registrationForm = this.fb.group(
      {
        userType: ['client', Validators.required],
        firstName: ['', Validators.required],
        lastName: ['', Validators.required],
        email: ['', [Validators.required, Validators.email]],
        password: ['', [Validators.required, Validators.minLength(8)]],
        confirmPassword: ['', Validators.required],
        agreeTerms: [false, [Validators.requiredTrue]],
        professionalDetails: this.fb.group({
          specialization: [''],
          experienceYears: [''],
          // File handling will be done separately, not in the form model
        }),
      },
      { validators: this.checkPasswordMatch }
    );
  }

  // Custom validator for checking if passwords match
  checkPasswordMatch(control: AbstractControl): ValidationErrors | null {
    const password = control.get('password');
    const confirmPassword = control.get('confirmPassword');

    if (password?.value !== confirmPassword?.value) {
      return { passwordMismatch: true };
    }
    return null;
  }

  // Add validators for professional fields when user selects professional type
  addProfessionalValidation(): void {
    const professionalDetails = this.registrationForm.get(
      'professionalDetails'
    ) as FormGroup;
    professionalDetails
      .get('specialization')
      ?.setValidators([Validators.required]);
    professionalDetails
      .get('experienceYears')
      ?.setValidators([Validators.required, Validators.min(0)]);
    professionalDetails.get('specialization')?.updateValueAndValidity();
    professionalDetails.get('experienceYears')?.updateValueAndValidity();
  }

  // Remove validators for professional fields when user selects client type
  removeProfessionalValidation(): void {
    const professionalDetails = this.registrationForm.get(
      'professionalDetails'
    ) as FormGroup;
    professionalDetails.get('specialization')?.clearValidators();
    professionalDetails.get('experienceYears')?.clearValidators();
    professionalDetails.get('specialization')?.updateValueAndValidity();
    professionalDetails.get('experienceYears')?.updateValueAndValidity();
  }

  // Helper method to check if user type is professional
  isProfessional(): boolean {
    return this.registrationForm.get('userType')?.value === 'professional';
  }

  // Helper method to get nested form controls safely
  getControl(path: string): AbstractControl | null {
    return this.registrationForm.get(path);
  }

  // Toggle password visibility
  togglePasswordVisibility(): void {
    this.passwordVisible = !this.passwordVisible;
  }

  // Toggle confirm password visibility
  toggleConfirmPasswordVisibility(): void {
    this.confirmPasswordVisible = !this.confirmPasswordVisible;
  }

  // Handle certification file upload
  onCertificationUpload(event: Event): void {
    const element = event.target as HTMLInputElement;
    if (element.files) {
      this.certificationError = null;

      for (let i = 0; i < element.files.length; i++) {
        const file = element.files[i];

        // Validate file type
        const validTypes = [
          'application/pdf',
          'image/jpeg',
          'image/jpg',
          'image/png',
        ];
        if (!validTypes.includes(file.type)) {
          this.certificationError = 'Only PDF, JPG, and PNG files are allowed.';
          continue;
        }

        // Validate file size
        if (file.size > this.MAX_CERTIFICATION_SIZE) {
          this.certificationError = 'File size must be less than 5MB.';
          continue;
        }

        this.certificationFiles.push(file);
      }
    }
  }

  // Handle resume file upload
  onResumeUpload(event: Event): void {
    const element = event.target as HTMLInputElement;
    if (element.files && element.files[0]) {
      this.resumeError = null;
      const file = element.files[0];

      // Validate file type
      if (file.type !== 'application/pdf') {
        this.resumeError = 'Only PDF files are allowed.';
        return;
      }

      // Validate file size
      if (file.size > this.MAX_RESUME_SIZE) {
        this.resumeError = 'File size must be less than 10MB.';
        return;
      }

      this.resumeFile = file;
    }
  }

  // Remove a certification file at specific index
  removeCertification(index: number): void {
    this.certificationFiles.splice(index, 1);
  }

  // Remove resume file
  removeResume(): void {
    this.resumeFile = null;
  }

  // Form submission
  onSubmit(): void {
    if (this.registrationForm.invalid) {
      // Mark all fields as touched to trigger validation messages
      this.markFormGroupTouched(this.registrationForm);
      return;
    }

    // Check if professional and required files are present
    if (this.isProfessional()) {
      if (this.certificationFiles.length === 0) {
        this.certificationError =
          'Please upload at least one certification document.';
        return;
      }

      if (!this.resumeFile) {
        this.resumeError = 'Please upload your resume/CV.';
        return;
      }
    }

    this.isSubmitting = true;

    // Create form data to send files along with form data
    const formData = new FormData();
    const formValue = this.registrationForm.value;
    formData.append('role', Role.USER);

    // Add basic user data
    Object.keys(formValue).forEach((key) => {
      if (key !== 'professionalDetails' && key !== 'confirmPassword') {
        formData.append(key, formValue[key]);
      }
    });

    // Add professional details if applicable
    if (this.isProfessional()) {
      formData.set('role', Role.PROFESSIONAL);
      Object.keys(formValue.professionalDetails).forEach((key) => {
        formData.append(
          `professionalDetails.${key}`,
          formValue.professionalDetails[key]
        );
      });

      // Add certification files
      this.certificationFiles.forEach((file, index) => {
        formData.append('certifications', file, file.name);
      });

      // Add resume file
      if (this.resumeFile) {
        formData.append('resume', this.resumeFile, this.resumeFile.name);
      }
    }

    // Call the registration service
    this.authService.register(formData).subscribe({
      next: (response) => {
        console.log('Registration successful', response);
        // Navigate to login page or dashboard based on your app flow
        this.router.navigate(['/auth/login'], {
          queryParams: { registered: 'success' },
        });
      },
      error: (error) => {
        console.error('Registration failed', error);
        this.isSubmitting = false;
        // Handle specific error messages here
      },
      complete: () => {
        this.isSubmitting = false;
      },
    });
  }

  // Helper method to mark all controls in a form group as touched
  private markFormGroupTouched(formGroup: FormGroup) {
    Object.values(formGroup.controls).forEach((control) => {
      control.markAsTouched();

      if (control instanceof FormGroup) {
        this.markFormGroupTouched(control);
      }
    });
  }
}

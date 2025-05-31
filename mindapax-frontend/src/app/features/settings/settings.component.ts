import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  FormsModule,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';

@Component({
  selector: 'app-settings',
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './settings.component.html',
  styleUrl: './settings.component.css',
})
export class SettingsComponent implements OnInit {
  profileForm: FormGroup;
  notificationForm: FormGroup;
  securityForm: FormGroup;
  billingForm: FormGroup;
  activeTab: string = 'profile';

  // Mock user data
  userData = {
    firstName: 'Adama',
    lastName: 'Traore',
    email: 'adama.traore@example.com',
    phone: '+1 (555) 123-4567',
    location: 'New York, NY',
    bio: 'I am focused on improving my mental and physical well-being through regular counseling and coaching sessions.',
    profileImage:
      'https://flowbite.com/docs/images/people/profile-picture-5.jpg',
  };

  constructor(private fb: FormBuilder) {
    this.profileForm = this.fb.group({
      firstName: [this.userData.firstName, Validators.required],
      lastName: [this.userData.lastName, Validators.required],
      email: [this.userData.email, [Validators.required, Validators.email]],
      phone: [this.userData.phone],
      location: [this.userData.location],
      bio: [this.userData.bio],
    });

    this.notificationForm = this.fb.group({
      emailNotifications: [true],
      smsNotifications: [true],
      sessionReminders: [true],
      promotionalEmails: [false],
      newsletterSubscription: [true],
    });

    this.securityForm = this.fb.group({
      currentPassword: ['', Validators.required],
      newPassword: ['', [Validators.required, Validators.minLength(8)]],
      confirmPassword: ['', Validators.required],
    });

    this.billingForm = this.fb.group({
      cardName: ['Adama Traore'],
      cardNumber: [''],
      expiryDate: [''],
      cvv: [''],
    });
  }

  ngOnInit(): void {
    // Any initialization code
  }

  setActiveTab(tab: string): void {
    this.activeTab = tab;
  }

  updateProfile(): void {
    if (this.profileForm.valid) {
      // Update profile implementation
      console.log('Profile updated', this.profileForm.value);
      // Show success notification
    }
  }

  updateNotifications(): void {
    if (this.notificationForm.valid) {
      // Update notifications implementation
      console.log(
        'Notification preferences updated',
        this.notificationForm.value
      );
      // Show success notification
    }
  }

  updatePassword(): void {
    if (this.securityForm.valid) {
      // Update password implementation
      console.log('Password updated');
      this.securityForm.reset();
      // Show success notification
    }
  }

  updateBilling(): void {
    if (this.billingForm.valid) {
      // Update billing implementation
      console.log('Billing information updated', this.billingForm.value);
      // Show success notification
    }
  }

  deleteAccount(): void {
    // Show confirmation modal before proceeding
    if (
      confirm(
        'Are you sure you want to delete your account? This action cannot be undone.'
      )
    ) {
      // Delete account implementation
      console.log('Account deleted');
    }
  }
}

import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';

@Component({
  selector: 'app-contact',
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './contact.component.html',
  styleUrl: './contact.component.css',
})
export class ContactComponent {
  contactForm: FormGroup;
  submitted = false;
  success = false;

  // Offices information
  offices = [
    {
      city: 'New York',
      address: '123 Wellness Ave, New York, NY 10001',
      phone: '+1 (212) 555-0123',
      email: 'newyork@mindapax.com',
      hours: 'Mon-Fri: 9am-6pm',
    },
    {
      city: 'San Francisco',
      address: '456 Health Street, San Francisco, CA 94105',
      phone: '+1 (415) 555-0156',
      email: 'sanfrancisco@mindapax.com',
      hours: 'Mon-Fri: 8am-5pm',
    },
    {
      city: 'London',
      address: '78 Wellness Road, London, UK E1 6AW',
      phone: '+44 20 7123 4567',
      email: 'london@mindapax.com',
      hours: 'Mon-Fri: 9am-5:30pm',
    },
  ];

  inquiryTypes = [
    'General Inquiry',
    'Technical Support',
    'Billing Question',
    'Partnership Opportunity',
    'Career Information',
    'Press Inquiry',
  ];

  constructor(private formBuilder: FormBuilder) {
    this.contactForm = this.formBuilder.group({
      firstName: ['', Validators.required],
      lastName: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      phone: [''],
      inquiryType: ['General Inquiry', Validators.required],
      message: ['', Validators.required],
      acceptTerms: [false, Validators.requiredTrue],
    });
  }

  // Getter for easy access to form fields
  get f() {
    return this.contactForm.controls;
  }

  onSubmit() {
    this.submitted = true;

    // Stop here if form is invalid
    if (this.contactForm.invalid) {
      return;
    }

    // TODO: Implement actual form submission logic
    console.log('Form submitted:', this.contactForm.value);

    // Simulate successful form submission
    setTimeout(() => {
      this.success = true;
      this.submitted = false;
      this.contactForm.reset();
      this.contactForm.patchValue({
        inquiryType: 'General Inquiry',
        acceptTerms: false,
      });
    }, 1500);
  }

  resetForm() {
    this.success = false;
    this.submitted = false;
    this.contactForm.reset();
    this.contactForm.patchValue({
      inquiryType: 'General Inquiry',
      acceptTerms: false,
    });
  }
}

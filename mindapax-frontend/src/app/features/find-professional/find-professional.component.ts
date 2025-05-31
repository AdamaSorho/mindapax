import { Component, OnInit } from '@angular/core';
import { Professional } from '../../models/professional.model';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { CommonModule, NgFor, NgIf } from '@angular/common';
import { Role } from '../../models/enums/role';
import {
  Specialization,
  SpecializationLabels,
  specializationOptions,
} from '../../models/enums/specialization';
import { ProfessionalService } from '../../services/professional.service';
import { ProfessionalFilterParams } from '../../models/network/professionalFilterParams';
import { ConnectionService } from '../../services/connection.service';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-find-professional',
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './find-professional.component.html',
  styleUrl: './find-professional.component.css',
})
export class FindProfessionalComponent implements OnInit {
  professionals: Professional[] = [];
  totalPages: number = 0;
  currentPage: number = 0;
  filterForm: FormGroup;
  searchTerm: string = '';
  specializationOptions = specializationOptions;
  selectedPro: Professional | null = null;
  currentUserId!: number;
  isModalOpen: boolean = false;
  filters: ProfessionalFilterParams = {
    firstName: '',
    lastName: '',
    specialization: '',
    experience: undefined,
    availabilityDate: '',
    status: 'ACTIVE', // For users
    page: 0,
    size: 10,
    sort: 'user.lastName,asc',
  };

  experienceLevels: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  languages: string[] = [
    'English',
    'Spanish',
    'French',
    'German',
    'Mandarin',
    'Arabic',
  ];
  availabilities: string[] = [
    'Weekdays',
    'Evenings',
    'Weekends',
    'Mornings',
    'Afternoons',
  ];
  priceRanges: string[] = ['Any', '$0-$50', '$50-$100', '$100-$150', '$150+'];

  constructor(
    private fb: FormBuilder,
    private professionalService: ProfessionalService,
    private connectionService: ConnectionService,
    private authService: AuthService
  ) {
    this.filterForm = this.fb.group({
      firstName: '',
      lastName: '',
      specialization: '',
      experience: undefined,
      language: '',
      availability: '',
      availabilityDate: '',
      priceRange: '',
    });
  }

  ngOnInit(): void {
    this.fetchProfessionals();
    this.currentUserId = this.authService.getUserId();
  }

  fetchProfessionals(): void {
    this.professionalService.searchProfessionals(this.filters).subscribe({
      next: (response) => {
        this.professionals = response.content;
        this.totalPages = response.totalPages;
        this.currentPage = response.page;
      },
      error: (error) => {
        console.error('Error fetching professionals:', error);
      },
    });
  }

  applyFilters(): void {
    const filters = this.filterForm.value;
    this.filters = {
      firstName: filters.firstName,
      lastName: filters.lastName,
      specialization: filters.specialization,
      experience: filters.experience,
      availabilityDate: filters.availabilityDate,
      status: 'ACTIVE', // For users
      page: 0,
      size: 10,
      sort: 'user.lastName,asc',
    };
    this.fetchProfessionals();
  }

  resetFilters(): void {
    this.filterForm.reset({
      specialization: '',
      experience: undefined,
      language: '',
      availability: '',
      priceRange: 'Any',
    });
    this.searchTerm = '';
    this.filters = {
      firstName: '',
      lastName: '',
      specialization: '',
      experience: undefined,
      availabilityDate: '',
      status: 'ACTIVE', // For users
      page: 0,
      size: 10,
      sort: 'user.lastName,asc',
    };
    this.applyFilters();
  }

  openProfileModal(pro: Professional): void {
    this.selectedPro = pro;
    this.isModalOpen = true;
    // For accessibility, prevent body scrolling when modal is open
    document.body.classList.add('overflow-hidden');
  }

  closeModal(): void {
    this.isModalOpen = false;
    document.body.classList.remove('overflow-hidden');
    // Give time for animation to complete before removing selected pro
    setTimeout(() => {
      this.selectedPro = null;
    }, 300);
  }

  connectWithProfessional(proId: number): void {
    this.connectionService
      .connectWithProfessional(this.currentUserId, proId)
      .subscribe({
        next: (connection) => {
          console.log('Connected with professional', connection);
        },
        error: (error) => {
          console.error('Error connecting with professional', error);
        },
      });
    this.closeModal();
  }

  // Optional: handle click outside to close modal
  onBackdropClick(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    if (target.id === 'profileModal') {
      this.closeModal();
    }
  }

  getSpecialization(specialization: string): string {
    return SpecializationLabels[specialization as Specialization];
  }
}

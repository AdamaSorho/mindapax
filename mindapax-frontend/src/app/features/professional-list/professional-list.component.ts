import { Component } from '@angular/core';
import { environment } from '../../../environments/environment';
import { initTabs } from 'flowbite';
import { ProfessionalService } from '../../services/professional.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Professional } from '../../models/professional.model';
import { Specialization } from '../../models/enums/specialization';
import {
  ProfessionalStatus,
  professionalStatusOptions,
} from '../../models/enums/professionalStatus';

@Component({
  selector: 'app-professional-list',
  imports: [CommonModule, FormsModule],
  templateUrl: './professional-list.component.html',
  styleUrl: './professional-list.component.css',
})
export class ProfessionalListComponent {
  professionals: Professional[] = [];
  filteredProfessionals: Professional[] = [];
  selectedProfessional: Professional | null = null;
  isModalOpen = false;
  isLoading = true;
  searchTerm = '';
  statusFilter = 'all';
  specialtyFilter = 'all';
  rejectionNote = '';
  professionalStatus = ProfessionalStatus;
  professionalStatusOptions = professionalStatusOptions;
  totalPages: number = 0;
  currentPage: number = 0;

  constructor(
    private professionalsService: ProfessionalService
  ) {}

  ngOnInit(): void {
    this.loadProfessionals();
  }

  ngAfterViewInit(): void {
    // Initialize tabs when modal is opened
    this.initializeTabsWhenModalOpens();
  }

  private initializeTabsWhenModalOpens(): void {
    // Using MutationObserver to detect when modal is added to DOM
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.addedNodes.length > 0) {
          const modal = document.getElementById('professionalDetailsModal');
          if (modal) {
            initTabs(); // Initialize Flowbite tabs
          }
        }
      });
    });

    // Start observing the document body for changes
    observer.observe(document.body, { childList: true, subtree: true });
  }

  loadProfessionals(): void {
    this.isLoading = true;
    this.professionalsService.getAllProfessionals().subscribe({
      next: (data) => {
        this.professionals = data.content;
        this.totalPages = data.totalPages;
        this.currentPage = data.page;
        this.applyFilters();
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading professionals', error);
        this.isLoading = false;
      },
    });
  }

  applyFilters(): void {
    this.filteredProfessionals = this.professionals.filter((pro) => {
      // Apply search filter
      const searchMatch =
        this.searchTerm === '' ||
        pro.user.firstName
          .toLowerCase()
          .includes(this.searchTerm.toLowerCase()) ||
        pro.specialization
          .toLowerCase()
          .includes(this.searchTerm.toLowerCase()) ||
        pro.user.email.toLowerCase().includes(this.searchTerm.toLowerCase());

      // Apply status filter
      const statusMatch =
        this.statusFilter === 'all' || pro.status === this.statusFilter;

      // Apply specialty filter
      const specialtyMatch =
        this.specialtyFilter === 'all' ||
        pro.specialization === this.specialtyFilter;

      return searchMatch && statusMatch && specialtyMatch;
    });
  }

  openModal(professional: Professional): void {
    this.selectedProfessional = professional;
    this.rejectionNote = '';
    this.isModalOpen = true;
  }

  closeModal(): void {
    this.isModalOpen = false;
    this.selectedProfessional = null;
  }

  approveProfessional(id: number): void {
    this.isLoading = true;
    this.professionalsService
      .updateProfessionalStatus(id, ProfessionalStatus.ACTIVE)
      .subscribe({
        next: () => {
          this.loadProfessionals();
          this.closeModal();
        },
        error: (error) => {
          console.error('Error approving professional', error);
          this.isLoading = false;
        },
      });
  }

  rejectProfessional(id: number): void {
    this.isLoading = true;
    this.professionalsService
      .updateProfessionalStatus(
        id,
        ProfessionalStatus.REJECTED,
        this.rejectionNote
      )
      .subscribe({
        next: () => {
          this.loadProfessionals();
          this.closeModal();
        },
        error: (error) => {
          console.error('Error rejecting professional', error);
          this.isLoading = false;
        },
      });
  }

  getSpecialtyList(): string[] {
    const specialties = new Set(
      this.professionals.map((pro) => pro.specialization)
    );
    return Array.from(specialties);
  }

  public getAbsoluteFileUrl(relativePath: string | undefined): string | undefined {
    if (!relativePath) {
      return undefined;
    }
    // If it's already a full URL (starts with http, https, or //), return it as is
    if (/^(https?:)?\/\//i.test(relativePath)) {
      return relativePath;
    }

    const apiUrl = environment.apiUrl; // Get from environment
    let baseUrl = '';

    try {
      // Attempt to parse apiUrl to get the origin (e.g., http://localhost:8080)
      // This handles cases where apiUrl might be like http://localhost:8080/api
      const url = new URL(apiUrl);
      baseUrl = url.origin;
    } catch (e) {
      // Fallback if apiUrl is not a full URL (e.g., just '/api')
      // In this case, make it relative to the frontend's current host.
      // This might be correct if a proxy is set up, or incorrect if files are served
      // directly by the backend on a different origin/path without proxying.
      console.warn("Failed to parse environment.apiUrl to extract origin. Assuming file paths are relative to the frontend host or a pre-configured proxy.", e);
      // If relativePath doesn't start with '/', add it.
      // This makes it an absolute path from the current host (e.g. /uploads/file.pdf)
      // return relativePath.startsWith('/') ? relativePath : '/' + relativePath;
      // For a more robust fallback, let's assume the backend paths might be like 'uploads/file.pdf'
      // and they should be served from the root of where the API is hosted.
      // If API is /api, and path is uploads/file.pdf, this will be /uploads/file.pdf
      // This is a common scenario for Spring Boot static resources.
      if (apiUrl.startsWith('http')) { // apiUrl is absolute, but parsing failed (should be rare)
          baseUrl = apiUrl.substring(0, apiUrl.indexOf('/', apiUrl.indexOf('//') + 2) !== -1 ? apiUrl.indexOf('/', apiUrl.indexOf('//') + 2) : apiUrl.length);
      } else { // apiUrl is relative itself e.g. /api
          baseUrl = ''; // Paths will be relative to current host
      }
    }

    // Ensure no double slashes if relativePath starts with one and baseUrl ends with one
    // And ensure there IS a slash if relativePath doesn't start with one.
    let finalUrl = baseUrl;
    if (finalUrl.endsWith('/') && relativePath.startsWith('/')) {
      finalUrl += relativePath.substring(1);
    } else if (!finalUrl.endsWith('/') && !relativePath.startsWith('/')) {
      finalUrl += '/' + relativePath;
    } else {
      finalUrl += relativePath;
    }
    return finalUrl;
  }
}

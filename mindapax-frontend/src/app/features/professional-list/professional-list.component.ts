import { Component } from '@angular/core';
import { environment } from '../../../environments/environment';
import { HttpClient, HttpResponse } from '@angular/common/http';
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
  public selectedTab: string = 'bio';

  constructor(
    private professionalsService: ProfessionalService,
    private http: HttpClient // Add this line
  ) {}

  ngOnInit(): void {
    this.loadProfessionals();
  }

  public selectTab(tabId: string, event: MouseEvent): void {
    // Try to blur an element within the modal content if it's currently focused
    // and is not the tab button itself, to prevent focus being trapped in an inert panel.
    const activeElement = document.activeElement as HTMLElement;
    if (event.currentTarget && activeElement) {
      const modalContent = (event.currentTarget as HTMLElement).closest(
        '.relative.bg-white.rounded-lg.shadow-lg.overflow-hidden'
      ); // Selector for the modal content box
      if (
        modalContent &&
        modalContent.contains(activeElement) &&
        activeElement !== event.currentTarget
      ) {
        activeElement.blur();
      }
    }

    this.selectedTab = tabId;

    // Set focus to the clicked tab button for accessibility
    if (event.currentTarget) {
      (event.currentTarget as HTMLElement).focus();
    }
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

  public getAbsoluteFileUrl(
    relativePath: string | undefined
  ): string | undefined {
    if (!relativePath) {
      return undefined;
    }

    // If it's already a full URL (starts with http, https, or //), return it as is
    if (/^(https?:)?\/\//i.test(relativePath)) {
      return relativePath;
    }

    const apiUrl = environment.apiUrl; // Get from environment
    let appOrigin = '';

    try {
      // Attempt to parse apiUrl to get the origin (e.g., http://localhost:8080)
      const url = new URL(apiUrl);
      appOrigin = url.origin;
    } catch (e) {
      console.warn(
        'Failed to parse environment.apiUrl to extract origin. Assuming relative to current host for file path construction.',
        e
      );
      // If apiUrl is not a full URL (e.g., just '/api'), appOrigin will be empty.
      // This means the final URL will be relative to the current frontend host, e.g., '/upload/...'
      // This might be correct if a proxy is configured to handle /upload paths.
      appOrigin = ''; // Fallback to construct paths relative to the current host if apiUrl is not absolute
    }

    // Remove leading slash from relativePath if present, as we are constructing the path carefully.
    const cleanRelativePath = relativePath.startsWith('/')
      ? relativePath.substring(1)
      : relativePath;

    // Construct the final URL: appOrigin + /upload/ + cleanRelativePath
    // Ensure there's exactly one slash between appOrigin and 'upload', and one between 'upload' and cleanRelativePath.
    let finalUrl = appOrigin;

    if (!finalUrl.endsWith('/')) {
      finalUrl += '/';
    }
  finalUrl += 'uploads/'; // Add the fixed base path

    if (cleanRelativePath) {
      // Only add cleanRelativePath if it's not empty
      finalUrl += cleanRelativePath;
    } else {
      // If cleanRelativePath is empty, we might have just appOrigin/upload/
      // Check if this is intended or if we should return undefined/error for empty relativePath
      // For now, allow it, it will result in 'http://origin/upload/'
    }

    return finalUrl;
  }

  public viewFile(
    fileUrlInput: string | undefined,
    defaultFileName: string
  ): void {
    if (!fileUrlInput) {
      console.error('File URL is undefined. Cannot view file.');
      // Consider showing a user-friendly error message here
      return;
    }

    this.http
      .get(fileUrlInput, { responseType: 'blob', observe: 'response' })
      .subscribe({
        next: (response: HttpResponse<Blob>) => {
          if (response.body) {
            const blob = response.body;
            let fileName = defaultFileName;

            const contentDisposition = response.headers.get(
              'Content-Disposition'
            );
            if (contentDisposition) {
              const filenameRegex = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/;
              const matches = filenameRegex.exec(contentDisposition);
              if (matches != null && matches[1]) {
                fileName = matches[1].replace(/['"]/g, '');
              }
            }

            const objectUrl = URL.createObjectURL(blob);
            const newTab = window.open(objectUrl, '_blank');

            if (!newTab) {
              console.error(
                'Failed to open new tab. A pop-up blocker might be active.'
              );
              // Consider showing a user-friendly error message here
            }

            // It's best practice to revoke the object URL to free up memory.
            // However, if the new tab is still using it, revoking too soon can break the display.
            // A common approach is to revoke it after a delay, assuming the new tab has loaded the content.
            setTimeout(() => URL.revokeObjectURL(objectUrl), 60 * 1000); // Revoke after 1 minute
          } else {
            console.error('Received an empty response body for the file.');
            // Consider showing a user-friendly error message here
          }
        },
        error: (error) => {
          console.error('Error fetching file:', error);
          // Consider showing a user-friendly error message here,
          // e.g., "Sorry, the file could not be loaded or accessed."
        },
      });
  }
}

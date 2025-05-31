import { Component } from '@angular/core';
import { ProfessionalService } from '../../services/professional.service';
import { TabService } from '../../services/business/tab.service';
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
    private professionalsService: ProfessionalService,
    private tabService: TabService
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
            this.tabService.initializeTabs('tab-content');
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
}

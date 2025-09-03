import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Professional } from '../../models/professional.model';
import { ConnectionService } from '../../services/connection.service';
import { ProfessionalService } from '../../services/professional.service';
import { AuthService } from '../../services/auth.service';
import { Connection } from '../../models/connection.model';
import { ConnectionStatus } from '../../models/enums/connectionStatus';

@Component({
  selector: 'app-connections',
  imports: [CommonModule, FormsModule],
  templateUrl: './connections.component.html',
  styleUrl: './connections.component.css',
})
export class ConnectionsComponent {
  connections: Connection[] = [];
  filteredConnections: Connection[] = [];
  professionals: Professional[] = [];

  connectionStatus = ConnectionStatus;

  selectedProfessional: string = '';
  adminNote: string = '';
  transferReason: string = '';

  sortBy: 'date' | 'urgency' = 'date';
  filterStatus: 'all' | 'pending' | 'accepted' | 'transferred' | 'escalated' =
    'pending';

  activeTab: 'pending' | 'accepted' | 'transferred' | 'all' = 'pending';
  isTransferModalOpen: boolean = false;
  isAdminModalOpen: boolean = false;
  currentConnectionId: number = 0;
  currentUserId: number;

  constructor(
    private connectionService: ConnectionService,
    private authService: AuthService,
    private professionalService: ProfessionalService
  ) {
    this.currentUserId = this.authService.getUserId();
  }

  ngOnInit(): void {
    this.loadConnections();
    this.applyFilters();
    this.loadProfessionals();
  }

  loadProfessionals(): void {
    // Load a list of professionals to choose for transfer. Adjust filters as needed.
    this.professionalService
      .getAllProfessionals(undefined, undefined, undefined, undefined, undefined, undefined, 0, 50)
      .subscribe({
        next: (page) => (this.professionals = page.content || []),
        error: (err) => console.error('Error loading professionals:', err),
      });
  }

  loadConnections(): void {
    this.connectionService.getConnections(this.currentUserId).subscribe({
      next: (connections) => {
        this.connections = connections;
        this.applyFilters();
      },
      error: (error) => {
        console.error('Error loading connections:', error);
      },
    });
  }

  filterConnectionsByStatus(status: ConnectionStatus): Connection[] {
    return this.connections.filter((c) => c.status === status);
  }

  changeTab(tab: 'pending' | 'accepted' | 'transferred' | 'all'): void {
    this.activeTab = tab;
    this.filterStatus = tab === 'all' ? 'all' : tab;
    this.applyFilters();
  }

  applyFilters(): void {
    // First filter by status
    this.filteredConnections =
      this.filterStatus === 'all'
        ? [...this.connections]
        : this.connections.filter(
            (conn) =>
              conn.status === this.getConnectionStatus(this.filterStatus)
          );

    // Then sort
    if (this.sortBy === 'date') {
      this.filteredConnections.sort(
        (a, b) => b.createdAt.getTime() - a.createdAt.getTime()
      );
    } else if (this.sortBy === 'urgency') {
      const urgencyValue = {
        HIGH: 3,
        MEDIUM: 2,
        LOW: 1,
      };

      this.filteredConnections.sort((a, b) => {
        const urgencyA = a.urgency ? urgencyValue[a.urgency] : 0;
        const urgencyB = b.urgency ? urgencyValue[b.urgency] : 0;

        return urgencyB - urgencyA;
      });
    }
  }

  changeSortBy(sort: 'date' | 'urgency'): void {
    this.sortBy = sort;
    this.applyFilters();
  }

  acceptConnection(connectionId: number): void {
    const connection = this.connections.find((c) => c.id === connectionId);
    if (connection) {
      connection.status = ConnectionStatus.ACCEPTED;
      this.applyFilters();
      this.updateConnection(connectionId, ConnectionStatus.ACCEPTED);
    }
  }

  updateConnection(
    connectionId: number,
    connectionStatus: ConnectionStatus
  ): void {
    this.connectionService
      .updateConnection(connectionId, connectionStatus)
      .subscribe({
        next: (updatedConnection) => {
          console.log('Connection updated:', updatedConnection);
          // Disregarding for now
          // const connection = this.connections.find(
          //   (c) => c.id === connectionId
          // );
          // if (connection) {
          //   connection.status = updatedConnection.status;
          //   this.applyFilters();
          // }
        },
        error: (error) => {
          console.error('Error updating connection:', error);
        },
      });
  }

  openTransferModal(connectionId: number): void {
    this.currentConnectionId = connectionId;
    this.selectedProfessional = '';
    this.transferReason = '';
    this.isTransferModalOpen = true;
  }

  closeTransferModal(): void {
    this.isTransferModalOpen = false;
  }

  transferToProf(): void {
    const connection = this.connections.find(
      (c) => c.id === this.currentConnectionId
    );
    if (!connection || !this.selectedProfessional) return;
    const proId = Number(this.selectedProfessional);
    this.connectionService
      .transferConnection(this.currentConnectionId, proId, this.transferReason)
      .subscribe({
        next: (updated) => {
          // Replace in local list
          const idx = this.connections.findIndex((c) => c.id === updated.id);
          if (idx >= 0) this.connections[idx] = updated;
          this.applyFilters();
          this.isTransferModalOpen = false;
        },
        error: (error) => {
          console.error('Error transferring connection:', error);
        },
      });
  }
  }

  openAdminModal(connectionId: number): void {
    this.currentConnectionId = connectionId;
    this.adminNote = '';
    this.isAdminModalOpen = true;
  }

  closeAdminModal(): void {
    this.isAdminModalOpen = false;
  }

  escalateToAdmin(): void {
    const connection = this.connections.find(
      (c) => c.id === this.currentConnectionId
    );
    if (connection) {
      connection.status = ConnectionStatus.ESCALATED;
      this.applyFilters();
      this.isAdminModalOpen = false;
      this.updateConnection(
        this.currentConnectionId,
        ConnectionStatus.ESCALATED
      );
    }
  }

  getUrgencyClass(urgency: string): string {
    switch (urgency) {
      case 'high':
        return 'bg-red-100 text-red-800';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'low':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }

  getConnectionStatus(
    tab: 'all' | 'pending' | 'accepted' | 'transferred' | 'escalated'
  ): string {
    switch (tab) {
      case 'pending':
        return ConnectionStatus.PENDING;
      case 'accepted':
        return ConnectionStatus.ACCEPTED;
      case 'transferred':
        return ConnectionStatus.TRANSFERRED;
      case 'escalated':
        return ConnectionStatus.ESCALATED;
      default:
        return ConnectionStatus.PENDING;
    }
  }
}

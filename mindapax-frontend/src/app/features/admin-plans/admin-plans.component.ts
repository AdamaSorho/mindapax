import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Plan, PlanAdminService } from '../../services/plan-admin.service';

@Component({
  selector: 'app-admin-plans',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-plans.component.html',
})
export class AdminPlansComponent {
  loading = false;
  error: string | null = null;
  plans: Plan[] = [];
  editing: Plan | null = null;
  draft: Plan = {
    name: '', price: 0, currency: 'XOF', billingCycle: 'MONTHLY', description: '', active: true, sessionAllowance: 0, features: [],
  };
  draftFeaturesText = '';
  editFeaturesText = '';

  constructor(private api: PlanAdminService) { this.load(); }

  load() {
    this.loading = true; this.error = null;
    this.api.list().subscribe({
      next: (list) => { this.plans = list; this.loading = false; },
      error: (e) => { this.error = 'Failed to load plans'; this.loading = false; }
    });
  }

  edit(p: Plan) { this.editing = { ...p }; this.editFeaturesText = (p.features || []).join('\n'); }
  cancel() { this.editing = null; this.draft = { name: '', price: 0, currency: 'XOF', billingCycle: 'MONTHLY', description: '', active: true, sessionAllowance: 0, features: [] }; this.draftFeaturesText=''; this.editFeaturesText=''; }

  saveNew() {
    this.loading = true; this.error = null;
    this.draft.features = this.draftFeaturesText.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
    this.api.create(this.draft).subscribe({
      next: (p) => { this.plans.push(p); this.cancel(); this.loading = false; },
      error: () => { this.error = 'Create failed'; this.loading = false; }
    });
  }

  saveEdit() {
    if (!this.editing || !this.editing.id) return;
    this.loading = true; this.error = null;
    this.editing.features = this.editFeaturesText.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
    this.api.update(this.editing.id, this.editing).subscribe({
      next: (p) => {
        const i = this.plans.findIndex(x => x.id === p.id);
        if (i >= 0) this.plans[i] = p; this.cancel(); this.loading = false;
      },
      error: () => { this.error = 'Update failed'; this.loading = false; }
    });
  }

  remove(id?: number) {
    if (!id) return;
    if (!confirm('Delete this plan?')) return;
    this.loading = true; this.error = null;
    this.api.delete(id).subscribe({
      next: () => { this.plans = this.plans.filter(p => p.id !== id); this.loading = false; },
      error: () => { this.error = 'Delete failed'; this.loading = false; }
    });
  }
}

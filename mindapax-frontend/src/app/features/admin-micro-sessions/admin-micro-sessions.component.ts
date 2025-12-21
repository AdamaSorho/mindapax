import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MicroSession, MicroSessionAdminService } from '../../services/micro-session-admin.service';

@Component({
  selector: 'app-admin-micro-sessions',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-micro-sessions.component.html',
})
export class AdminMicroSessionsComponent {
  loading = false;
  error: string | null = null;
  sessions: MicroSession[] = [];
  editing: MicroSession | null = null;
  submitted = false;
  editSubmitted = false;

  draft: MicroSession = {
    title: '',
    description: '',
    domain: 'MIND',
    outcomes: [],
    minutes: 5,
    steps: [],
  };

  draftOutcomesText = '';
  draftStepsText = '';
  editOutcomesText = '';
  editStepsText = '';

  domains = ['MIND', 'MONEY', 'BODY', 'RELATIONSHIPS', 'GROWTH', 'INTEGRATED', 'CUSTOM'];

  constructor(private api: MicroSessionAdminService) {
    this.load();
  }

  load() {
    this.loading = true;
    this.error = null;
    this.api.list().subscribe({
      next: (list) => {
        this.sessions = list;
        this.loading = false;
      },
      error: () => {
        this.error = 'Failed to load micro sessions';
        this.loading = false;
      },
    });
  }

  edit(session: MicroSession) {
    this.editing = { ...session };
    this.editOutcomesText = (session.outcomes || []).join('\n');
    this.editStepsText = (session.steps || []).join('\n');
    this.editSubmitted = false;
  }

  cancel() {
    this.editing = null;
    this.draft = {
      title: '',
      description: '',
      domain: 'MIND',
      outcomes: [],
      minutes: 5,
      steps: [],
    };
    this.draftOutcomesText = '';
    this.draftStepsText = '';
    this.editOutcomesText = '';
    this.editStepsText = '';
    this.submitted = false;
    this.editSubmitted = false;
  }

  saveNew() {
    this.submitted = true;
    this.error = null;
    const outcomes = this.splitLines(this.draftOutcomesText);
    const steps = this.splitLines(this.draftStepsText);
    if (this.isBlank(this.draft.title) ||
        this.isBlank(this.draft.description) ||
        this.isBlank(this.draft.domain) ||
        !this.draft.minutes ||
        this.draft.minutes < 1 ||
        outcomes.length === 0 ||
        steps.length === 0) {
      this.error = 'Please fill in all required fields.';
      return;
    }
    this.loading = true;
    this.draft.outcomes = outcomes;
    this.draft.steps = steps;
    this.api.create(this.draft).subscribe({
      next: (session) => {
        this.sessions.push(session);
        this.cancel();
        this.loading = false;
      },
      error: () => {
        this.error = 'Create failed';
        this.loading = false;
      },
    });
  }

  saveEdit() {
    if (!this.editing || !this.editing.id) return;
    this.editSubmitted = true;
    this.error = null;
    const outcomes = this.splitLines(this.editOutcomesText);
    const steps = this.splitLines(this.editStepsText);
    if (this.isBlank(this.editing.title) ||
        this.isBlank(this.editing.description) ||
        this.isBlank(this.editing.domain) ||
        !this.editing.minutes ||
        this.editing.minutes < 1 ||
        outcomes.length === 0 ||
        steps.length === 0) {
      this.error = 'Please fill in all required fields.';
      return;
    }
    this.loading = true;
    this.editing.outcomes = outcomes;
    this.editing.steps = steps;
    this.api.update(this.editing.id, this.editing).subscribe({
      next: (session) => {
        const i = this.sessions.findIndex((s) => s.id === session.id);
        if (i >= 0) this.sessions[i] = session;
        this.cancel();
        this.loading = false;
      },
      error: () => {
        this.error = 'Update failed';
        this.loading = false;
      },
    });
  }

  remove(id?: number) {
    if (!id) return;
    if (!confirm('Delete this micro session?')) return;
    this.loading = true;
    this.error = null;
    this.api.delete(id).subscribe({
      next: () => {
        this.sessions = this.sessions.filter((s) => s.id !== id);
        this.loading = false;
      },
      error: () => {
        this.error = 'Delete failed';
        this.loading = false;
      },
    });
  }

  private splitLines(value: string): string[] {
    return value
      .split(/\r?\n/)
      .map((s) => s.trim())
      .filter(Boolean);
  }

  private isBlank(value?: string | null): boolean {
    return !value || value.trim().length === 0;
  }
}

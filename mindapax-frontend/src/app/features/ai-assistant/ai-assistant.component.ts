import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NgFor } from '@angular/common';
import { AiAssistantService } from '../../services/ai-assistant.service';

@Component({
  selector: 'app-ai-assistant',
  standalone: true,
  imports: [FormsModule, NgFor],
  templateUrl: './ai-assistant.component.html',
  styleUrl: './ai-assistant.component.css',
})
export class AiAssistantComponent {
  message = '';
  replies: string[] = [];

  constructor(private aiService: AiAssistantService) {}

  send(): void {
    const text = this.message.trim();
    if (!text) {
      return;
    }
    this.message = '';
    this.aiService.sendMessage(text).subscribe({
      next: (res) => this.replies.push(res.reply),
      error: (err) => console.error('AI error', err),
    });
  }
}


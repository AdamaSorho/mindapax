import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NgFor, NgClass } from '@angular/common';
import { AiAssistantService } from '../../services/ai-assistant.service';

@Component({
  selector: 'app-ai-assistant',
  standalone: true,
  imports: [FormsModule, NgFor, NgClass],
  templateUrl: './ai-assistant.component.html',
  styleUrl: './ai-assistant.component.css',
})
export class AiAssistantComponent {
  message = '';
  messages: { sender: 'user' | 'assistant'; text: string }[] = [];

  constructor(private aiService: AiAssistantService) {}

  send(): void {
    const text = this.message.trim();
    if (!text) {
      return;
    }
    this.messages.push({ sender: 'user', text });
    this.message = '';
    this.aiService.sendMessage(text).subscribe({
      next: (res) => this.messages.push({ sender: 'assistant', text: res.reply }),
      error: (err) => console.error('AI error', err),
    });
  }
}


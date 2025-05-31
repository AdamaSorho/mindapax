import { Component, OnDestroy, OnInit } from '@angular/core';
import { Message } from '../../models/message.model';
import { Conversation } from '../../models/conversation.model';
import { NgClass, NgFor, NgIf } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MessageService } from '../../services/message.service';
import { AuthService } from '../../services/auth.service';
import { ConversationService } from '../../services/conversation.service';
import { User } from '../../models/user.model';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-messages',
  imports: [NgClass, NgIf, NgFor, FormsModule],
  templateUrl: './messages.component.html',
  styleUrl: './messages.component.css',
  standalone: true,
})
export class MessagesComponent implements OnInit, OnDestroy {
  currentUserId!: number;
  conversations: Conversation[] = [];
  messages: Message[] = [];
  selectedConversation: Conversation | null = null;
  newMessage: string = '';
  page: number = 0;
  size: number = 10;

  // Add connection status tracking
  isConnected: boolean = false;
  isLoadingMessages: boolean = false;
  reconnecting: boolean = false;

  // Subscriptions for proper cleanup
  private messageSubscription?: Subscription;
  private connectionStatusSubscription?: Subscription;

  constructor(
    private messageService: MessageService,
    private authService: AuthService,
    private conversationService: ConversationService
  ) {}

  ngOnInit(): void {
    // Monitor WebSocket connection status
    this.connectionStatusSubscription =
      this.messageService.connectionStatus$.subscribe((status) => {
        this.isConnected = status;

        // If connection drops but we have a selected conversation, try to reconnect
        if (
          !status &&
          this.selectedConversation &&
          this.authService.isAuthenticated
        ) {
          this.reconnecting = true;
          setTimeout(() => {
            if (this.selectedConversation) {
              this.messageService.connectWebSocket(
                this.selectedConversation.id
              );
            }
            this.reconnecting = false;
          }, 3000);
        }
      });

    // Subscribe to incoming messages
    this.messageSubscription = this.messageService
      .onMessage()
      .subscribe((message: Message) => {
        // Only handle messages for the current conversation
        if (
          this.selectedConversation &&
          message.conversationId === this.selectedConversation.id
        ) {
          // Add message to the list
          this.messages.push(message);

          // Mark as read if it's not from current user
          if (message.senderId !== this.currentUserId) {
            message.isRead = true;
          }

          // Update the conversation's last message
          if (this.selectedConversation) {
            this.selectedConversation.lastMessage = message;
          }

          // Update the conversation list to reflect changes
          this.updateConversationInList(message);
        } else {
          // If message is for a different conversation, increment unread count
          const conversation = this.conversations.find(
            (c) => c.id === message.conversationId
          );
          if (conversation) {
            conversation.unreadCount = (conversation.unreadCount || 0) + 1;
            conversation.lastMessage = message;

            // Move this conversation to the top of the list
            this.moveConversationToTop(conversation);
          }
        }
      });

    this.currentUserId = this.authService.getUserId();
    this.fetchConversations();
  }

  isProfessional(): boolean {
    return this.authService.getRoles().includes('ROLE_PROFESSIONAL');
  }

  getParticipant(conversation: Conversation): User {
    if (this.isProfessional()) {
      return conversation.user;
    } else {
      return conversation.professional.user;
    }
  }

  fetchConversations(): void {
    this.conversationService
      .getConversations(this.currentUserId, this.page, this.size)
      .subscribe({
        next: (response) => {
          this.conversations = response.content;

          // Sort conversations by most recent message
          this.sortConversationsByDate();
        },
        error: (error) => {
          console.error('Error fetching conversations:', error);

          // If 401 error, try token refresh then retry
          if (error.status === 401 && this.authService.isTokenExpired()) {
            this.authService.refreshToken().subscribe({
              next: () => this.fetchConversations(),
              error: (refreshError) =>
                console.error('Failed to refresh token:', refreshError),
            });
          }
        },
      });
  }

  selectConversation(conversation: Conversation): void {
    // Disconnect from previous WebSocket if switching conversations
    if (
      this.selectedConversation &&
      this.selectedConversation.id !== conversation.id
    ) {
      this.messageService.disconnectWebSocket();
    }

    this.selectedConversation = conversation;

    // Mark messages as read
    conversation.unreadCount = 0;

    // Clear previous messages
    this.messages = [];

    // Fetch messages
    this.fetchMessages(conversation.id);
  }

  fetchMessages(conversationId: number): void {
    this.isLoadingMessages = true;

    this.messageService.getMessageHistory(conversationId).subscribe({
      next: (response) => {
        this.messages = response.content;
        this.isLoadingMessages = false;

        // Mark all messages from other users as read
        this.markMessagesAsRead(conversationId);
      },
      error: (error) => {
        console.error('Error fetching messages:', error);
        this.isLoadingMessages = false;
      },
    });

    // Connect to WebSocket to receive real-time messages
    if (!this.isConnected) {
      this.messageService.connectWebSocket(conversationId);
    }
  }

  sendMessage(): void {
    if (
      this.newMessage.trim() === '' ||
      !this.selectedConversation ||
      !this.isConnected
    )
      return;

    const newMsg: Message = {
      senderId: this.currentUserId,
      conversationId: this.selectedConversation!.id,
      content: this.newMessage,
      timestamp: new Date(),
      isRead: false,
    };

    // Update the conversation's last message
    this.selectedConversation.lastMessage = newMsg;

    // Move this conversation to the top
    this.moveConversationToTop(this.selectedConversation);

    // Clear the input
    this.newMessage = '';

    // Send message via WebSocket
    this.messageService.sendMessage(newMsg).subscribe({
      error: (error) => {
        console.error('Error sending message:', error);

        // Handle token expiration during send
        if (
          error.toString().includes('WebSocket not connected') ||
          error.toString().includes('Unauthorized')
        ) {
          // Try to reconnect WebSocket with fresh token
          if (this.selectedConversation) {
            this.messageService.disconnectWebSocket();

            // Try to refresh token first
            this.authService.refreshToken().subscribe({
              next: () => {
                if (this.selectedConversation) {
                  this.messageService.connectWebSocket(
                    this.selectedConversation.id
                  );
                  // Re-send message after reconnection
                  setTimeout(() => {
                    if (this.isConnected) {
                      this.messageService.sendMessage(newMsg).subscribe();
                    }
                  }, 1000);
                }
              },
              error: (refreshError) =>
                console.error('Failed to refresh token:', refreshError),
            });
          }
        }
      },
    });
  }

  markMessagesAsRead(conversationId: number): void {
    // Mark messages as read on server
    // This would be a separate API call to your backend
    // e.g., this.messageService.markAsRead(conversationId, this.currentUserId)

    // For now, mark as read locally
    this.messages.forEach((message) => {
      if (message.senderId !== this.currentUserId) {
        message.isRead = true;
      }
    });
  }

  loadMoreMessages(): void {
    if (!this.selectedConversation || this.isLoadingMessages) return;

    this.page++;
    this.isLoadingMessages = true;

    this.messageService
      .getMessageHistory(this.selectedConversation.id, this.page, this.size)
      .subscribe({
        next: (response) => {
          // Prepend older messages at the beginning
          this.messages = [...response.content, ...this.messages];
          this.isLoadingMessages = false;
        },
        error: (error) => {
          console.error('Error loading more messages:', error);
          this.isLoadingMessages = false;
          this.page--; // Revert page increment on error
        },
      });
  }

  formatTime(date: Date): string {
    return new Date(date).toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  formatDate(date: Date): string {
    const messageDate = new Date(date);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (messageDate.toDateString() === today.toDateString()) {
      return 'Today';
    } else if (messageDate.toDateString() === yesterday.toDateString()) {
      return 'Yesterday';
    } else {
      return messageDate.toLocaleDateString([], {
        month: 'short',
        day: 'numeric',
      });
    }
  }

  isMessageFromCurrentUser(message: Message): boolean {
    return message.senderId === this.currentUserId;
  }

  // Move a conversation to the top of the list (most recent)
  private moveConversationToTop(conversation: Conversation): void {
    const index = this.conversations.findIndex((c) => c.id === conversation.id);
    if (index > 0) {
      // Remove conversation from current position
      this.conversations.splice(index, 1);
      // Add at the beginning
      this.conversations.unshift(conversation);
    }
  }

  // Sort conversations by most recent message
  private sortConversationsByDate(): void {
    this.conversations.sort((a, b) => {
      const dateA = a.lastMessage?.timestamp
        ? new Date(a.lastMessage.timestamp)
        : new Date(0);
      const dateB = b.lastMessage?.timestamp
        ? new Date(b.lastMessage.timestamp)
        : new Date(0);
      return dateB.getTime() - dateA.getTime();
    });
  }

  // Update a conversation in the list when a new message arrives
  private updateConversationInList(message: Message): void {
    const conversation = this.conversations.find(
      (c) => c.id === message.conversationId
    );
    if (conversation) {
      conversation.lastMessage = message;
      // If message is from the current user, ensure it's read
      if (message.senderId === this.currentUserId) {
        message.isRead = true;
      }
      this.moveConversationToTop(conversation);
    }
  }

  ngOnDestroy(): void {
    // Clean up subscriptions to prevent memory leaks
    if (this.messageSubscription) {
      this.messageSubscription.unsubscribe();
    }

    if (this.connectionStatusSubscription) {
      this.connectionStatusSubscription.unsubscribe();
    }

    // Disconnect from WebSocket
    this.messageService.disconnectWebSocket();
  }
}

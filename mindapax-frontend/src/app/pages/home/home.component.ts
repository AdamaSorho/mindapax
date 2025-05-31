import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

@Component({
  selector: 'app-home',
  imports: [CommonModule],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css',
})
export class HomeComponent {
  testimonials = [
    {
      id: 1,
      name: 'Sarah Johnson',
      role: 'Marketing Executive',
      image: 'https://placehold.co/150',
      quote:
        'Mindapax has transformed my approach to mental health. The professionals here are incredible and the platform is so easy to use!',
    },
    {
      id: 2,
      name: 'Michael Chen',
      role: 'Software Engineer',
      image: 'https://placehold.co/150',
      quote:
        'As someone who works remotely, having access to financial coaching through Mindapax has helped me plan for my future with confidence.',
    },
    {
      id: 3,
      name: 'Amara Patel',
      role: 'Small Business Owner',
      image: 'https://placehold.co/150',
      quote:
        'The holistic approach to wellbeing is what sets Mindapax apart. Mental, physical, and financial health all in one place has been a game-changer.',
    },
  ];
}

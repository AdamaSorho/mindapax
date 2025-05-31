import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

@Component({
  selector: 'app-about',
  imports: [CommonModule],
  templateUrl: './about.component.html',
  styleUrl: './about.component.css',
})
export class AboutComponent {
  teamMembers = [
    {
      id: 1,
      name: 'Dr. Elena Rodriguez',
      role: 'Founder & CEO',
      image: 'https://placehold.co/300',
      bio: 'With over 15 years of experience in clinical psychology and entrepreneurship, Dr. Rodriguez founded Mindapax with a vision to make holistic wellness accessible to everyone.',
    },
    {
      id: 2,
      name: 'Marcus Johnson',
      role: 'Director of Mental Health Services',
      image: 'https://placehold.co/300',
      bio: 'A licensed therapist specializing in cognitive behavioral therapy, Marcus ensures our mental health services meet the highest standards of care and effectiveness.',
    },
    {
      id: 3,
      name: 'Sophia Chen',
      role: 'Head of Financial Wellness',
      image: 'https://placehold.co/300',
      bio: 'Certified financial planner with expertise in personal finance and financial therapy, helping clients achieve both financial stability and peace of mind.',
    },
    {
      id: 4,
      name: 'David Okafor',
      role: 'Physical Wellness Director',
      image: 'https://placehold.co/300',
      bio: 'Former professional athlete and certified fitness coach, David leads our physical wellness initiatives with a focus on sustainable, personalized health practices.',
    },
  ];

  partners = [
    {
      id: 1,
      name: 'National Mental Health Association',
      logo: 'https://placehold.co/200x100',
    },
    {
      id: 2,
      name: 'Financial Planning Institute',
      logo: 'https://placehold.co/200x100',
    },
    {
      id: 3,
      name: 'Global Wellness Alliance',
      logo: 'https://placehold.co/200x100',
    },
    {
      id: 4,
      name: 'Preventive Healthcare Coalition',
      logo: 'https://placehold.co/200x100',
    },
  ];
}

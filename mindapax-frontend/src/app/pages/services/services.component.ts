import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

interface Service {
  id: number;
  title: string;
  description: string;
  icon: string;
  features: string[];
  popular?: boolean;
}

@Component({
  selector: 'app-services',
  imports: [CommonModule],
  templateUrl: './services.component.html',
  styleUrl: './services.component.css',
})
export class ServicesComponent {
  services: Service[] = [
    {
      id: 1,
      title: 'Mental Wellness',
      description:
        'Professional therapy and counseling sessions to support your mental health journey.',
      icon: 'fa-brain',
      features: [
        'One-on-one therapy sessions',
        'Group counseling options',
        'Stress management techniques',
        'Depression and anxiety support',
        'Personalized mental health plans',
      ],
      popular: true,
    },
    {
      id: 2,
      title: 'Financial Coaching',
      description:
        'Expert guidance to help you achieve your financial goals and secure your future.',
      icon: 'fa-chart-line',
      features: [
        'Personal budget planning',
        'Investment strategy sessions',
        'Debt reduction planning',
        'Retirement preparation',
        'Financial literacy education',
      ],
    },
    {
      id: 3,
      title: 'Physical Wellness',
      description:
        'Customized fitness and nutrition programs to optimize your physical health.',
      icon: 'fa-dumbbell',
      features: [
        'Personalized workout plans',
        'Nutrition consultation',
        'Sleep improvement strategies',
        'Injury prevention techniques',
        'Holistic health assessment',
      ],
    },
  ];

  featuredProfessionals = [
    {
      id: 1,
      name: 'Dr. Sarah Johnson',
      specialization: 'Mental Health Therapist',
      rating: 4.9,
      image: 'https://placehold.co/400x300',
    },
    {
      id: 2,
      name: 'Michael Chen',
      specialization: 'Financial Advisor',
      rating: 4.8,
      image: 'https://placehold.co/400x300',
    },
    {
      id: 3,
      name: 'Aisha Patel',
      specialization: 'Fitness & Nutrition Coach',
      rating: 4.7,
      image: 'https://placehold.co/400x300',
    },
  ];

  faqs = [
    {
      question: 'How do I choose the right professional for my needs?',
      answer:
        'We recommend starting with our matching quiz that evaluates your goals and preferences. You can also browse professionals by specialty and read their reviews from other clients.',
    },
    {
      question: 'What happens during the first session?',
      answer:
        "Your first session is typically an introduction where the professional will get to know you, understand your goals, and outline a plan for future sessions. You can ask questions and determine if they're the right fit for you.",
    },
    {
      question: 'How often should I schedule sessions?',
      answer:
        'This varies based on your needs and the recommendation of your professional. Many clients start with weekly sessions and adjust the frequency as they progress.',
    },
    {
      question: "Can I change professionals if I'm not satisfied?",
      answer:
        'Absolutely! We want you to find the perfect match. You can switch professionals at any time without any penalty.',
    },
  ];
}

import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';

interface TimeSlot {
  id: number;
  day: string;
  date: string;
  slots: {
    time: string;
    available: boolean;
  }[];
}

interface Review {
  id: number;
  userName: string;
  userImage: string;
  rating: number;
  date: string;
  comment: string;
}

@Component({
  selector: 'app-professional-profile',
  imports: [FormsModule, CommonModule, RouterModule],
  templateUrl: './professional-profile.component.html',
  styleUrl: './professional-profile.component.css',
})
export class ProfessionalProfileComponent {
  professionalId: number = 0;

  professional = {
    id: 1,
    name: 'Dr. Sarah Johnson',
    image: 'https://placehold.co/400x400?text=Dr.+Sarah+Johnson',
    title: 'Clinical Psychologist',
    category: 'mental',
    specialties: [
      'Anxiety',
      'Depression',
      'Stress Management',
      'Trauma Recovery',
    ],
    rating: 4.9,
    reviewCount: 127,
    experience: 12,
    languages: ['English', 'Spanish'],
    education: [
      {
        degree: 'Ph.D. Clinical Psychology',
        institution: 'Stanford University',
        year: '2011',
      },
      {
        degree: 'M.A. Psychology',
        institution: 'University of California, Berkeley',
        year: '2008',
      },
      {
        degree: 'B.S. Psychology',
        institution: 'University of Washington',
        year: '2006',
      },
    ],
    certifications: [
      {
        name: 'Licensed Clinical Psychologist',
        authority: 'State Board of Psychology',
        year: '2012',
      },
      {
        name: 'Cognitive Behavioral Therapy Certification',
        authority: 'American Psychological Association',
        year: '2014',
      },
      {
        name: 'Trauma-Focused Therapy Certification',
        authority: 'International Association of Trauma Professionals',
        year: '2016',
      },
    ],
    bio: "Dr. Sarah Johnson is a licensed clinical psychologist with over 12 years of experience helping individuals overcome anxiety, depression, and trauma. She specializes in cognitive behavioral therapy and mindfulness-based approaches, tailoring treatment to each client's unique needs. Dr. Johnson creates a safe, supportive environment where clients can explore challenges and develop effective coping strategies. Prior to private practice, she worked at the Veterans Affairs Medical Center and taught at Stanford University. She is passionate about making mental healthcare accessible and breaking down stigmas surrounding mental health.",
    approach:
      "I believe in a collaborative, client-centered approach that respects your unique experiences and goals. My practice integrates evidence-based techniques from cognitive behavioral therapy, mindfulness, and trauma-informed care. Together, we'll identify patterns that may be holding you back and develop practical strategies to help you thrive. I create a warm, non-judgmental space where you can feel safe exploring difficult emotions and experiences.",
    sessionPrice: 85,
    sessionTypes: ['Video Call', 'Phone Call', 'In-Person'],
    availability: ['Monday', 'Wednesday', 'Friday'],
  };

  timeSlots: TimeSlot[] = [
    {
      id: 1,
      day: 'Monday',
      date: 'Mar 10, 2025',
      slots: [
        { time: '9:00 AM', available: true },
        { time: '10:00 AM', available: false },
        { time: '11:00 AM', available: true },
        { time: '1:00 PM', available: true },
        { time: '2:00 PM', available: true },
        { time: '3:00 PM', available: false },
      ],
    },
    {
      id: 2,
      day: 'Wednesday',
      date: 'Mar 12, 2025',
      slots: [
        { time: '9:00 AM', available: true },
        { time: '10:00 AM', available: true },
        { time: '11:00 AM', available: true },
        { time: '1:00 PM', available: false },
        { time: '2:00 PM', available: true },
        { time: '3:00 PM', available: true },
      ],
    },
    {
      id: 3,
      day: 'Friday',
      date: 'Mar 14, 2025',
      slots: [
        { time: '9:00 AM', available: true },
        { time: '10:00 AM', available: true },
        { time: '11:00 AM', available: false },
        { time: '1:00 PM', available: false },
        { time: '2:00 PM', available: true },
        { time: '3:00 PM', available: true },
      ],
    },
  ];

  reviews: Review[] = [
    {
      id: 1,
      userName: 'Michael T.',
      userImage: 'https://placehold.co/50x50?text=MT',
      rating: 5,
      date: 'February 15, 2025',
      comment:
        "Dr. Johnson has been incredibly helpful in my journey to manage anxiety. Her approach is both compassionate and practical. I've developed useful techniques that have made a real difference in my daily life.",
    },
    {
      id: 2,
      userName: 'Jennifer K.',
      userImage: 'https://placehold.co/50x50?text=JK',
      rating: 5,
      date: 'January 23, 2025',
      comment:
        "I've been working with Dr. Johnson for about 6 months, and the progress I've made is remarkable. She creates a safe space to explore difficult topics and provides actionable strategies to move forward.",
    },
    {
      id: 3,
      userName: 'David L.',
      userImage: 'https://placehold.co/50x50?text=DL',
      rating: 4,
      date: 'December 4, 2024',
      comment:
        'Dr. Johnson is professional, knowledgeable, and genuinely caring. I appreciate her thoughtful approach to therapy and her ability to adapt to my needs as they evolve over time.',
    },
  ];

  selectedSessionType: string = 'Video Call';
  selectedTimeSlot: { day: string; date: string; time: string } | null = null;
  activeTab: string = 'about';

  constructor(private route: ActivatedRoute) {}

  ngOnInit(): void {
    this.route.params.subscribe((params) => {
      this.professionalId = +params['id'];
      // In a real application, you would fetch the professional data using this ID
    });
  }

  selectTimeSlot(day: string, date: string, time: string): void {
    this.selectedTimeSlot = { day, date, time };
  }

  renderStars(rating: number): number[] {
    return Array(Math.floor(rating)).fill(0);
  }

  showPartialStar(rating: number): boolean {
    return rating % 1 >= 0.5;
  }

  setActiveTab(tab: string): void {
    this.activeTab = tab;
  }
}

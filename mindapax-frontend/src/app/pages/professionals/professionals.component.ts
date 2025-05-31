import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

interface Professional {
  id: number;
  name: string;
  image: string;
  specialization: string;
  category: 'mental' | 'financial' | 'physical';
  experience: number;
  languages: string[];
  rating: number;
  sessionPrice: number;
  availability: string[];
  featured?: boolean;
}

@Component({
  selector: 'app-professionals',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './professionals.component.html',
  styleUrl: './professionals.component.css',
})
export class ProfessionalsComponent {
  professionals: Professional[] = [
    {
      id: 1,
      name: 'Dr. Sarah Johnson',
      image: 'https://placehold.co/300x300',
      specialization: 'Clinical Psychologist',
      category: 'mental',
      experience: 12,
      languages: ['English', 'Spanish'],
      rating: 4.9,
      sessionPrice: 85,
      availability: ['Mon', 'Wed', 'Fri'],
      featured: true,
    },
    {
      id: 2,
      name: 'Michael Chen',
      image: 'https://placehold.co/300x300',
      specialization: 'Financial Advisor',
      category: 'financial',
      experience: 8,
      languages: ['English', 'Mandarin'],
      rating: 4.8,
      sessionPrice: 75,
      availability: ['Tue', 'Thu', 'Sat'],
    },
    {
      id: 3,
      name: 'Aisha Patel',
      image: 'https://placehold.co/300x300',
      specialization: 'Fitness & Nutrition Coach',
      category: 'physical',
      experience: 10,
      languages: ['English', 'Hindi'],
      rating: 4.7,
      sessionPrice: 65,
      availability: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    },
    {
      id: 4,
      name: 'Dr. James Wilson',
      image: 'https://placehold.co/300x300',
      specialization: 'Psychiatrist',
      category: 'mental',
      experience: 15,
      languages: ['English'],
      rating: 4.9,
      sessionPrice: 95,
      availability: ['Mon', 'Tue', 'Thu'],
      featured: true,
    },
    {
      id: 5,
      name: 'Sofia Rodriguez',
      image: 'https://placehold.co/300x300',
      specialization: 'Life Coach',
      category: 'mental',
      experience: 6,
      languages: ['English', 'Spanish', 'Portuguese'],
      rating: 4.6,
      sessionPrice: 60,
      availability: ['Wed', 'Thu', 'Fri', 'Sat'],
    },
    {
      id: 6,
      name: 'Robert Kim',
      image: 'https://placehold.co/300x300?text=Robert+Kim',
      specialization: 'Investment Specialist',
      category: 'financial',
      experience: 14,
      languages: ['English', 'Korean'],
      rating: 4.8,
      sessionPrice: 90,
      availability: ['Mon', 'Wed', 'Fri'],
    },
    {
      id: 7,
      name: 'Emma Thompson',
      image: 'https://placehold.co/300x300?text=Emma+Thompson',
      specialization: 'Personal Trainer',
      category: 'physical',
      experience: 7,
      languages: ['English', 'French'],
      rating: 4.5,
      sessionPrice: 55,
      availability: ['Tue', 'Thu', 'Sat', 'Sun'],
    },
    {
      id: 8,
      name: 'David Nguyen',
      image: 'https://placehold.co/300x300?text=David+Nguyen',
      specialization: 'Retirement Planner',
      category: 'financial',
      experience: 11,
      languages: ['English', 'Vietnamese'],
      rating: 4.7,
      sessionPrice: 80,
      availability: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    },
  ];

  filteredProfessionals: Professional[] = [];

  // Filter options
  categories: string[] = [
    'All',
    'Mental Health',
    'Financial Coaching',
    'Physical Wellness',
  ];
  experienceLevels: string[] = [
    'Any Experience',
    '0-5 years',
    '5-10 years',
    '10+ years',
  ];
  languages: string[] = [
    'Any Language',
    'English',
    'Spanish',
    'Mandarin',
    'Hindi',
    'Korean',
    'French',
    'Vietnamese',
    'Portuguese',
  ];
  priceRanges: string[] = ['Any Price', '$50-$70', '$70-$90', '$90+'];

  // Selected filters
  selectedCategory: string = 'All';
  selectedExperience: string = 'Any Experience';
  selectedLanguage: string = 'Any Language';
  selectedPrice: string = 'Any Price';
  searchTerm: string = '';

  constructor() {}

  ngOnInit(): void {
    this.filteredProfessionals = [...this.professionals];
  }

  applyFilters(): void {
    this.filteredProfessionals = this.professionals.filter((pro) => {
      // Category filter
      if (this.selectedCategory !== 'All') {
        const categoryMap: { [key: string]: string } = {
          'Mental Health': 'mental',
          'Financial Coaching': 'financial',
          'Physical Wellness': 'physical',
        };
        if (pro.category !== categoryMap[this.selectedCategory]) {
          return false;
        }
      }

      // Experience filter
      if (this.selectedExperience !== 'Any Experience') {
        if (this.selectedExperience === '0-5 years' && pro.experience > 5) {
          return false;
        } else if (
          this.selectedExperience === '5-10 years' &&
          (pro.experience < 5 || pro.experience > 10)
        ) {
          return false;
        } else if (
          this.selectedExperience === '10+ years' &&
          pro.experience < 10
        ) {
          return false;
        }
      }

      // Language filter
      if (
        this.selectedLanguage !== 'Any Language' &&
        !pro.languages.includes(this.selectedLanguage)
      ) {
        return false;
      }

      // Price filter
      if (this.selectedPrice !== 'Any Price') {
        if (
          this.selectedPrice === '$50-$70' &&
          (pro.sessionPrice < 50 || pro.sessionPrice > 70)
        ) {
          return false;
        } else if (
          this.selectedPrice === '$70-$90' &&
          (pro.sessionPrice < 70 || pro.sessionPrice > 90)
        ) {
          return false;
        } else if (this.selectedPrice === '$90+' && pro.sessionPrice < 90) {
          return false;
        }
      }

      // Search term filter
      if (
        this.searchTerm &&
        !pro.name.toLowerCase().includes(this.searchTerm.toLowerCase()) &&
        !pro.specialization
          .toLowerCase()
          .includes(this.searchTerm.toLowerCase())
      ) {
        return false;
      }

      return true;
    });
  }

  resetFilters(): void {
    this.selectedCategory = 'All';
    this.selectedExperience = 'Any Experience';
    this.selectedLanguage = 'Any Language';
    this.selectedPrice = 'Any Price';
    this.searchTerm = '';
    this.filteredProfessionals = [...this.professionals];
  }
}

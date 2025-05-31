export interface Recommendation {
  id: number;
  title: string;
  description: string;
  icon: string;
  category: 'mental' | 'physical' | 'financial';
}

export interface PagedResponse<T> {
  totalPages: number;
  totalElements: number;
  page: number;
  size: number;
  content: T[];
  empty: boolean;
  isLast: boolean;
}

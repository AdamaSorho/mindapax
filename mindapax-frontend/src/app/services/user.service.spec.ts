import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { UserService } from './user.service';
import { User } from '../models/user.model';
import { PagedResponse } from '../models/network/pagedResponse'; // Import PagedResponse
import { environment } from '../../environments/environment';
import { Role } from '../models/enums/role';

describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;
  const apiUrl = environment.apiUrl + '/users';

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [UserService]
    });
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify(); // Make sure that there are no outstanding requests
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('getUsers', () => {
    it('should fetch users from the API via GET', () => {
      const mockUsers: User[] = [
        { id: 1, firstName: 'John', lastName: 'Doe', email: 'john@example.com', role: Role.USER, avatar: '', phone: '', location: '' },
        { id: 2, firstName: 'Jane', lastName: 'Smith', email: 'jane@example.com', role: Role.PROFESSIONAL, avatar: '', phone: '', location: '' }
      ];

      service.getUsers().subscribe(users => {
        expect(users.length).toBe(2);
        expect(users).toEqual(mockUsers); // Should still receive the content array
      });

      const mockPagedResponse: PagedResponse<User> = {
        content: mockUsers,
        totalPages: 1,
        totalElements: 2,
        page: 0,
        size: 10,
        empty: false,
        isLast: true
        // Add other PagedResponse fields as defined in your interface if necessary for completeness,
        // but 'content' is the most crucial for this test.
      };

      const req = httpMock.expectOne(apiUrl);
      expect(req.request.method).toBe('GET');
      req.flush(mockPagedResponse); // Flush the PagedResponse object
    });

    it('should handle errors when fetching users', () => {
      const errorMessage = 'Mock network error';
      service.getUsers().subscribe({
        next: () => fail('should have failed with the network error'),
        error: (error) => {
          expect(error.statusText).toEqual(errorMessage);
        }
      });

      const req = httpMock.expectOne(apiUrl);
      req.flush(errorMessage, { status: 500, statusText: errorMessage });
    });
  });
});

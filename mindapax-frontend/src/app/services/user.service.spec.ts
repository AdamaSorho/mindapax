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
  // Note: The apiUrl in the service itself is now just environment.apiUrl,
  // and the full path is constructed in the method.
  // For the test, we'll define the expected endpoint.
  const expectedBaseUrl = environment.apiUrl;

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
    it('should fetch connected users for a professional from the API via GET with pagination params', () => {
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
        size: 50, // Matches the default size in service
        empty: false,
        isLast: true
      };

      // Construct the expected URL with query parameters
      const expectedUrl = `${expectedBaseUrl}/professionals/me/connected-users?page=0&size=50`;
      const req = httpMock.expectOne(expectedUrl);
      // Alternatively, to check params separately:
      // const req = httpMock.expectOne(request => request.url === `${expectedBaseUrl}/professionals/me/connected-users`);
      // expect(req.request.params.get('page')).toEqual('0');
      // expect(req.request.params.get('size')).toEqual('50');

      expect(req.request.method).toBe('GET');
      req.flush(mockPagedResponse); // Flush the PagedResponse object
    });

    it('should handle errors when fetching connected users', () => {
      const errorMessage = 'Mock network error';
      service.getUsers().subscribe({
        next: () => fail('should have failed with the network error'),
        error: (error) => {
          expect(error.statusText).toEqual(errorMessage);
        }
      });

      const expectedUrl = `${expectedBaseUrl}/professionals/me/connected-users?page=0&size=50`;
      const req = httpMock.expectOne(expectedUrl);
      req.flush(errorMessage, { status: 500, statusText: errorMessage });
    });
  });
});

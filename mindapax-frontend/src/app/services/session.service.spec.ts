import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { SessionService, ScheduleSessionPayload } from './session.service';
import { Session } from '../models/session.model';
import { SessionMode } from '../models/enums/SessionFilter';
import { environment } from '../../environments/environment';

describe('SessionService', () => {
  let service: SessionService;
  let httpMock: HttpTestingController;
  const baseUrl = environment.apiUrl + '/sessions';

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [SessionService]
    });
    service = TestBed.inject(SessionService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('scheduleSessionByProfessional', () => {
    it('should send a POST request to schedule a session', () => {
      const mockPayload: ScheduleSessionPayload = {
        userId: 1,
        startTime: new Date().toISOString(),
        endTime: new Date(Date.now() + 3600 * 1000).toISOString(), // 1 hour later
        mode: SessionMode.VIDEO,
        notes: 'Test session'
      };

      const mockResponse: Session = { // Assuming Session model structure
        id: 123,
        userId: mockPayload.userId,
        startTime: mockPayload.startTime,
        endTime: mockPayload.endTime,
        mode: mockPayload.mode,
        notes: mockPayload.notes,
        status: 'SCHEDULED', // Or whatever status is expected
        professionalId: 10,
        professionalName: 'Dr. Who',
        professionalSpecialization: 'Time Travel'
      };

      service.scheduleSessionByProfessional(mockPayload).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });

      const req = httpMock.expectOne(`${baseUrl}/professional/schedule`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(mockPayload);
      req.flush(mockResponse);
    });

    it('should handle errors when scheduling a session', () => {
      const mockPayload: ScheduleSessionPayload = {
        userId: 1,
        startTime: new Date().toISOString(),
        endTime: new Date(Date.now() + 3600 * 1000).toISOString(),
        mode: SessionMode.VIDEO,
        notes: 'Test session'
      };
      const errorMessage = 'Mock network error';

      service.scheduleSessionByProfessional(mockPayload).subscribe({
        next: () => fail('should have failed with the network error'),
        error: (error) => {
          expect(error.statusText).toEqual(errorMessage);
        }
      });

      const req = httpMock.expectOne(`${baseUrl}/professional/schedule`);
      req.flush(errorMessage, { status: 500, statusText: errorMessage });
    });
  });
});

import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { SessionService, ScheduleSessionPayload } from './session.service';
import { Session } from '../models/session.model';
import { ZoomSignatureResponse } from '../models/zoom-signature-response.model';
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
    it('should send a POST request to schedule a session with durationMinutes', () => {
      const startTimeISO = new Date().toISOString();
      const mockPayload: ScheduleSessionPayload = {
        userId: 1,
        startTime: startTimeISO,
        durationMinutes: 60, // Use durationMinutes
        mode: SessionMode.VIDEO,
        notes: 'Test session'
      };

      const mockResponse: Session = {
        id: 123,
        userId: mockPayload.userId,
        startTime: mockPayload.startTime,
        durationMinutes: mockPayload.durationMinutes, // Use durationMinutes
        mode: mockPayload.mode,
        notes: mockPayload.notes,
        status: 'SCHEDULED',
        professionalId: 10,
        professionalName: 'Dr. Who',
        professionalSpecialization: 'Time Travel'
      };

      service.scheduleSessionByProfessional(mockPayload).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });

      const req = httpMock.expectOne(`${baseUrl}/professional/schedule`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(mockPayload); // Ensure payload sent matches
      req.flush(mockResponse);
    });

    it('should handle errors when scheduling a session', () => {
      const mockPayload: ScheduleSessionPayload = {
        userId: 1,
        startTime: new Date().toISOString(),
        durationMinutes: 60, // Use durationMinutes
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

  describe('getZoomMeetingSignature', () => {
    it('should fetch Zoom meeting signature successfully', () => {
      const mockSessionId = '123';
      const mockResponse: ZoomSignatureResponse = {
        apiKey: 'testKey',
        meetingNumber: 'testMeetingNum',
        signature: 'testSignature'
      };

      service.getZoomMeetingSignature(mockSessionId).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });

      const expectedUrl = `${baseUrl}/${mockSessionId}/join-video`;
      const req = httpMock.expectOne(expectedUrl);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({}); // Expects an empty body for POST
      req.flush(mockResponse);
    });

    it('should handle error when fetching Zoom meeting signature', () => {
      const mockSessionId = '123';
      const errorMessage = 'Http failure response for (unknown url): 404 Not Found'; // This is a typical error message string from HttpErrorResponse

      service.getZoomMeetingSignature(mockSessionId).subscribe({
        next: () => fail('should have failed with the 404 error'),
        error: (error) => {
          expect(error.status).toBe(404);
          // For a more robust check, you might inspect error.message or error.error if the backend provides a structured error
        }
      });

      const expectedUrl = `${baseUrl}/${mockSessionId}/join-video`;
      const req = httpMock.expectOne(expectedUrl);
      expect(req.request.method).toBe('POST');
      // Simulate an error response
      req.flush(errorMessage, { status: 404, statusText: 'Not Found' });
    });
  });
});

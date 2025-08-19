import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { AiAssistantService } from './ai-assistant.service';
import { environment } from '../../environments/environment';

describe('AiAssistantService', () => {
  let service: AiAssistantService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
    });
    service = TestBed.inject(AiAssistantService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    http.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should post message', () => {
    service.sendMessage('hello').subscribe();
    const req = http.expectOne(`${environment.apiUrl}/assistant`);
    expect(req.request.method).toBe('POST');
    req.flush({ reply: 'hi' });
  });
});


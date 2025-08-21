import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AiAssistantComponent } from './ai-assistant.component';
import { AiAssistantService } from '../../services/ai-assistant.service';
import { of } from 'rxjs';

describe('AiAssistantComponent', () => {
  let component: AiAssistantComponent;
  let fixture: ComponentFixture<AiAssistantComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AiAssistantComponent],
      providers: [{
        provide: AiAssistantService,
        useValue: { sendMessage: () => of({ reply: 'test' }) },
      }],
    }).compileComponents();

    fixture = TestBed.createComponent(AiAssistantComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});


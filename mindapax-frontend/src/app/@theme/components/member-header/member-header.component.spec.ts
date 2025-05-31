import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MemberHeaderComponent } from './member-header.component';

describe('MemberHeaderComponent', () => {
  let component: MemberHeaderComponent;
  let fixture: ComponentFixture<MemberHeaderComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MemberHeaderComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MemberHeaderComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

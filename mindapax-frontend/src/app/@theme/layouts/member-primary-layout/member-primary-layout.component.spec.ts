import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MemberPrimaryLayoutComponent } from './member-primary-layout.component';

describe('MemberPrimaryLayoutComponent', () => {
  let component: MemberPrimaryLayoutComponent;
  let fixture: ComponentFixture<MemberPrimaryLayoutComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MemberPrimaryLayoutComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MemberPrimaryLayoutComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

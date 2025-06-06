import { ComponentFixture, TestBed, fakeAsync, tick } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { ActivatedRoute, convertToParamMap, Router } from '@angular/router';
import { ZoomMeetingComponent } from './zoom-meeting.component';
import { PLATFORM_ID } from '@angular/core';
import { of } from 'rxjs';

// Mock the global ZoomMtg object
// This is crucial for testing components that interact with external, non-Angular libraries.
const mockZoomMtg = {
  setZoomJSLib: jasmine.createSpy('setZoomJSLib'),
  preLoadWasm: jasmine.createSpy('preLoadWasm'),
  prepareWebSDK: jasmine.createSpy('prepareWebSDK'),
  init: jasmine.createSpy('init').and.callFake((config: any) => {
    // Simulate successful initialization by calling the success callback
    if (config.success) {
      config.success({ status: true }); // Mock success payload
    }
  }),
  join: jasmine.createSpy('join').and.callFake((config: any) => {
    // Simulate successful join
    if (config.success) {
      config.success({ status: true }); // Mock success payload
    }
  }),
  leaveMeeting: jasmine.createSpy('leaveMeeting'),
  getMeetingStatus: jasmine.createSpy('getMeetingStatus').and.returnValue(3) // Simulate 'INMEETING' status
};

describe('ZoomMeetingComponent', () => {
  let component: ZoomMeetingComponent;
  let fixture: ComponentFixture<ZoomMeetingComponent>;
  let mockActivatedRoute: any;
  let mockRouter: any;

  // Initial mock params
  const initialMockParams = {
    sdkKey: 'testSdkKey',
    meetingNumber: 'testMeetingNumber',
    signature: 'testSignature',
    userName: 'Test User',
    userEmail: 'test@example.com'
  };

  beforeEach(async () => {
    // Reset spies before each test
    mockZoomMtg.setZoomJSLib.calls.reset();
    mockZoomMtg.preLoadWasm.calls.reset();
    mockZoomMtg.prepareWebSDK.calls.reset();
    mockZoomMtg.init.calls.reset();
    mockZoomMtg.join.calls.reset();
    mockZoomMtg.leaveMeeting.calls.reset();
    mockZoomMtg.getMeetingStatus.calls.reset().and.returnValue(3);


    mockActivatedRoute = {
      // Use 'of' to return an Observable for queryParams
      queryParams: of(convertToParamMap(initialMockParams))
    };

    mockRouter = {
      navigate: jasmine.createSpy('navigate')
    };

    // Provide the mock global ZoomMtg object
    (window as any).ZoomMtg = mockZoomMtg;

    // Create a mock for document.getElementById for #zmmtg-root
    spyOn(document, 'getElementById').and.returnValue(document.createElement('div'));

    await TestBed.configureTestingModule({
      declarations: [ZoomMeetingComponent],
      imports: [RouterTestingModule], // RouterTestingModule can be useful
      providers: [
        { provide: ActivatedRoute, useValue: mockActivatedRoute },
        { provide: Router, useValue: mockRouter },
        { provide: PLATFORM_ID, useValue: 'browser' } // Simulate browser environment
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(ZoomMeetingComponent);
    component = fixture.componentInstance;
    // fixture.detectChanges(); // ngOnInit is called here
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize and join meeting on init if parameters are present', fakeAsync(() => {
    // Set params again if ngOnInit logic relies on them directly without waiting for subscription if test setup changes
    component.sdkKey = initialMockParams.sdkKey;
    component.meetingNumber = initialMockParams.meetingNumber;
    component.signature = initialMockParams.signature;
    component.userName = initialMockParams.userName;
    component.userEmail = initialMockParams.userEmail;

    fixture.detectChanges(); // Triggers ngOnInit and ngAfterViewInit due to fakeAsync
    tick(); // Process observables from queryParams

    expect(component.sdkKey).toBe(initialMockParams.sdkKey);
    // ngAfterViewInit calls loadZoomSdkAndJoinMeeting
    expect(mockZoomMtg.setZoomJSLib).toHaveBeenCalledWith('/assets/zoom-sdk/lib', '/av');
    expect(mockZoomMtg.preLoadWasm).toHaveBeenCalled();
    expect(mockZoomMtg.prepareWebSDK).toHaveBeenCalled();
    expect(mockZoomMtg.init).toHaveBeenCalled();
    // join is called from init's success callback
    expect(mockZoomMtg.join).toHaveBeenCalledWith(jasmine.objectContaining({
      sdkKey: initialMockParams.sdkKey,
      meetingNumber: initialMockParams.meetingNumber,
      signature: initialMockParams.signature,
      userName: initialMockParams.userName,
      userEmail: initialMockParams.userEmail
    }));
  }));

  it('should not initialize if sdkKey is missing', fakeAsync(() => {
    mockActivatedRoute.queryParams = of(convertToParamMap({
        // sdkKey is missing
        meetingNumber: 'testMeetingNumber',
        signature: 'testSignature',
     }));
    fixture.detectChanges(); // ngOnInit
    tick(); // process observables

    // Re-create component with new route params to ensure ngOnInit picks them up
    // This is tricky because component is already created.
    // Better to set component properties directly or re-init component for this specific test condition.
    component.sdkKey = null as any; // Simulate missing sdkKey after initial setup
    component.meetingNumber = 'testMeetingNumber';
    component.signature = 'testSignature';

    component.ngAfterViewInit(); // Manually call for this specific condition if ngOnInit doesn't re-evaluate

    expect(mockZoomMtg.init).not.toHaveBeenCalled();
    expect(mockZoomMtg.join).not.toHaveBeenCalled();
  }));

  it('should call ZoomMtg.leaveMeeting on destroy if in meeting', () => {
    mockZoomMtg.getMeetingStatus.and.returnValue(3); // Simulate in meeting status
    component.ngOnDestroy();
    expect(mockZoomMtg.leaveMeeting).toHaveBeenCalled();
  });

  it('should NOT call ZoomMtg.leaveMeeting on destroy if not in meeting', () => {
    mockZoomMtg.getMeetingStatus.and.returnValue(0); // Simulate idle status
    component.ngOnDestroy();
    expect(mockZoomMtg.leaveMeeting).not.toHaveBeenCalled();
  });

  // Test for ZoomMtg.init error
  it('should handle ZoomMtg.init error', fakeAsync(() => {
    mockZoomMtg.init.and.callFake((config: any) => {
        if (config.error) config.error({ errorCode: 1, errorMessage: "Init failed" });
    });
    spyOn(console, 'error');

    component.sdkKey = initialMockParams.sdkKey;
    component.meetingNumber = initialMockParams.meetingNumber;
    component.signature = initialMockParams.signature;

    fixture.detectChanges(); // ngOnInit
    tick(); // ngAfterViewInit

    expect(mockZoomMtg.init).toHaveBeenCalled();
    expect(console.error).toHaveBeenCalledWith('Zoom SDK initialization failed:', { errorCode: 1, errorMessage: "Init failed" });
    expect(mockZoomMtg.join).not.toHaveBeenCalled();
  }));

  // Test for ZoomMtg.join error
  it('should handle ZoomMtg.join error', fakeAsync(() => {
    // Ensure init succeeds
    mockZoomMtg.init.and.callFake((config: any) => {
        if (config.success) config.success({ status: true });
    });
    // Make join fail
    mockZoomMtg.join.and.callFake((config: any) => {
        if (config.error) config.error({ errorCode: 1, errorMessage: "Join failed" });
    });
    spyOn(console, 'error');

    component.sdkKey = initialMockParams.sdkKey;
    component.meetingNumber = initialMockParams.meetingNumber;
    component.signature = initialMockParams.signature;

    fixture.detectChanges(); // ngOnInit
    tick(); // ngAfterViewInit

    expect(mockZoomMtg.init).toHaveBeenCalled();
    expect(mockZoomMtg.join).toHaveBeenCalled();
    expect(console.error).toHaveBeenCalledWith('Error joining Zoom meeting:', { errorCode: 1, errorMessage: "Join failed" });
  }));

});

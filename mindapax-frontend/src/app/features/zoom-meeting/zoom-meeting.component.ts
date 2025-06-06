import { Component, OnInit, OnDestroy, AfterViewInit, Inject, PLATFORM_ID } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { isPlatformBrowser } from '@angular/common';
// Declare ZoomMtg for TypeScript. This assumes the Zoom SDK is loaded globally.
declare var ZoomMtg: any;

@Component({
  selector: 'app-zoom-meeting',
  templateUrl: './zoom-meeting.component.html',
  styleUrls: ['./zoom-meeting.component.css']
})
export class ZoomMeetingComponent implements OnInit, OnDestroy, AfterViewInit {

  // These will be passed via route query parameters or state
  // Or, ideally, fetched securely if not passed via route.
  // For this implementation, we'll use route snapshot query params.
  sdkKey: string = '';
  meetingNumber: string = '';
  signature: string = '';
  userName: string = 'User'; // Placeholder, fetch from auth service or route
  userEmail: string = ''; // Placeholder, fetch from auth service or route
  passWord = ''; // Zoom Meeting Password, if any. Not used in JWT auth usually for joining.
  role = 0; // 0 for attendee, 1 for host. Passed in signature, but SDK might use it.

  private isBrowser: boolean;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    @Inject(PLATFORM_ID) platformId: Object
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  ngOnInit(): void {
    if (!this.isBrowser) {
      return;
    }
    // Retrieve parameters from route query params
    this.route.queryParams.subscribe(params => {
      this.sdkKey = params['sdkKey'];
      this.meetingNumber = params['meetingNumber'];
      this.signature = params['signature'];
      this.userName = params['userName'] || 'Mindapax User'; // TODO: Get from AuthService
      this.userEmail = params['userEmail'] || ''; // TODO: Get from AuthService (optional for some SDK setups)
      // this.passWord = params['passWord'] || ''; // If you use meeting passwords

      if (!this.sdkKey || !this.meetingNumber || !this.signature) {
        console.error('Zoom meeting parameters are missing!');
        // Optionally navigate back or show an error message
        // this.router.navigate(['/']);
        return;
      }
    });
  }

  ngAfterViewInit(): void {
    if (!this.isBrowser) {
      return;
    }
    if (this.sdkKey && this.meetingNumber && this.signature) {
        this.loadZoomSdkAndJoinMeeting();
    } else {
        console.error("Cannot join Zoom meeting due to missing parameters in ngAfterViewInit.");
    }
  }

  loadZoomSdkAndJoinMeeting(): void {
    // Dynamically set the Zoom Web SDK resource path (points to the /lib folder within your assets)
    // This path should correspond to where you copied the 'lib' folder from the Zoom SDK dist.
    ZoomMtg.setZoomJSLib('/assets/zoom-sdk/lib', '/av'); // Adjust path as needed

    ZoomMtg.preLoadWasm(); // Preload WebAssembly resources
    ZoomMtg.prepareWebSDK(); // Prepare the SDK

    ZoomMtg.init({
      leaveUrl: '/sessions', // URL to redirect to after leaving meeting. TODO: Make this more dynamic, e.g., back to session list or dashboard.
      isSupportAV: true, // Enable audio/video
      success: (success: any) => {
        console.log('Zoom SDK initialized successfully:', success);
        this.joinMeeting();
      },
      error: (error: any) => {
        console.error('Zoom SDK initialization failed:', error);
      }
    });
  }

  joinMeeting(): void {
    ZoomMtg.join({
      sdkKey: this.sdkKey,
      signature: this.signature,
      meetingNumber: this.meetingNumber,
      userName: this.userName,
      userEmail: this.userEmail, // Optional: email of the user
      passWord: this.passWord,   // Optional: meeting password
      // role: this.role, // Role is part of signature, not typically set here for JWT
      success: (success: any) => {
        console.log('Joined Zoom meeting successfully:', success);
        // Make the Zoom meeting UI visible if it was hidden
        document.getElementById('zmmtg-root')!.style.display = 'block';
      },
      error: (error: any) => {
        console.error('Error joining Zoom meeting:', error);
        // Handle error, e.g., show message to user, navigate away
        // this.router.navigate(['/sessions'], { queryParams: { error: 'join_failed' } });
      }
    });
  }

  ngOnDestroy(): void {
    if (this.isBrowser && typeof ZoomMtg !== 'undefined' && ZoomMtg.getMeetingStatus) {
      // Check if in a meeting before trying to leave
      const meetingStatus = ZoomMtg.getMeetingStatus();
      // MEETING_STATUS_IDLE = 0, MEETING_STATUS_CONNECTING = 1, MEETING_STATUS_WAITINGFORHOST = 2,
      // MEETING_STATUS_INMEETING = 3, MEETING_STATUS_RECONNECTING = 4
      if (meetingStatus === 3 || meetingStatus === 2) {
        ZoomMtg.leaveMeeting({});
        console.log('Left Zoom meeting on component destroy.');
      }
    }
  }
}

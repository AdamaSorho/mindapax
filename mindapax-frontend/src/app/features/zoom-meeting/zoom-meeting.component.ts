import {
  Component,
  OnInit,
  OnDestroy,
  AfterViewInit,
  Inject,
  PLATFORM_ID,
  NgZone,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { isPlatformBrowser } from '@angular/common';
import { ZoomMtg } from '@zoom/meetingsdk';
import ZoomMtgEmbedded from '@zoom/meetingsdk/embedded';

@Component({
  selector: 'app-zoom-meeting',
  templateUrl: './zoom-meeting.component.html',
  styleUrls: ['./zoom-meeting.component.css'],
})
export class ZoomMeetingComponent implements OnInit {
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

  client = ZoomMtgEmbedded.createClient();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private ngZone: NgZone,
    @Inject(PLATFORM_ID) platformId: Object
  ) {}

  ngOnInit(): void {
    // Retrieve parameters from route query params
    this.route.queryParams.subscribe((params) => {
      this.sdkKey = params['sdkKey'];
      this.meetingNumber = params['meetingNumber'];
      this.signature = params['signature'];
      this.userName = params['userName'] || 'Mindapax User'; // TODO: Get from AuthService
      this.userEmail = params['userEmail'] || ''; // TODO: Get from AuthService (optional for some SDK setups)
      this.passWord = params['passWord'] || ''; // If you use meeting passwords

      if (!this.sdkKey || !this.meetingNumber || !this.signature) {
        console.error('Zoom meeting parameters are missing!');
        // Optionally navigate back or show an error message
        // this.router.navigate(['/']);
        return;
      }
    });
    this.loadZoomSdkAndJoinMeeting();
  }

  loadZoomSdkAndJoinMeeting(): void {
    // document.getElementById('zmmtg-root')!.style.display = 'block';
    let meetingSdkElement = document.getElementById('zmmtg-root') ?? undefined;

    this.ngZone.runOutsideAngular(() => {
      this.client
        .init({
          zoomAppRoot: meetingSdkElement,
          language: 'en-US',
          patchJsMedia: true,
          leaveOnPageUnload: true,
        })
        .then(() => {
          this.client.join({
            sdkKey: this.sdkKey,
            signature: this.signature,
            meetingNumber: this.meetingNumber,
            userName: this.userName,
            userEmail: this.userEmail, // Optional: email of the user
            password: this.passWord,
            // role: this.role, // Role is part of signature, not typically set here for JWT
            success: (success: any) => {
              console.log('Joined Zoom meeting successfully:', success);
              // Make the Zoom meeting UI visible if it was hidden
              // document.getElementById('zmmtg-root')!.style.display = 'block';
              console.log('Joined Zoom meeting successfully:', success);
            },
            error: (error: any) => {
              console.error('Error joining Zoom meeting:', error);
              // Handle error, e.g., show message to user, navigate away
              // this.router.navigate(['/sessions'], { queryParams: { error: 'join_failed' } });
            },
          });
        });
    });

    // this.ngZone.runOutsideAngular(() => {
    //   ZoomMtg.init({
    //     leaveUrl: '/member/sessions',
    //     patchJsMedia: true,
    //     leaveOnPageUnload: true,
    //     success: (success: any) => {
    //       console.log('Zoom SDK initialized successfully:', success);
    //       this.joinMeeting();
    //     },
    //     error: (error: any) => {
    //       console.error('Zoom SDK initialization failed:', error);
    //     },
    //   });
    // });
  }

  joinMeeting(): void {
    console.log('meeting number', this.meetingNumber);
    ZoomMtg.join({
      sdkKey: this.sdkKey,
      signature: this.signature,
      meetingNumber: this.meetingNumber,
      userName: this.userName,
      userEmail: this.userEmail, // Optional: email of the user
      passWord: this.passWord, // Optional: meeting password
      // role: this.role, // Role is part of signature, not typically set here for JWT
      success: (success: any) => {
        console.log('Joined Zoom meeting successfully:', success);
        // Make the Zoom meeting UI visible if it was hidden
        // document.getElementById('zmmtg-root')!.style.display = 'block';
        console.log('Joined Zoom meeting successfully:', success);
      },
      error: (error: any) => {
        console.error('Error joining Zoom meeting:', error);
        // Handle error, e.g., show message to user, navigate away
        // this.router.navigate(['/sessions'], { queryParams: { error: 'join_failed' } });
      },
    });
  }
}

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

  registrantToken = '';
  zakToken = '';

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
        console.error(
          'Zoom meeting parameters are missing or invalid. SDK Key:',
          this.sdkKey,
          'Meeting Number:',
          this.meetingNumber,
          'Signature:',
          this.signature
        );
        // TODO: Implement a user-friendly error display/notification service.
        // For now, we can use a simple alert or navigate back with an error.
        alert(
          'Error: Could not join the meeting. Essential parameters are missing or invalid. Please try again or contact support.'
        );
        // Optionally, navigate the user away or disable further actions.
        // Example: this.router.navigate(['/sessions'], { queryParams: { error: 'meeting_params_missing' } });
        return; // Important to stop further execution
      }
      // Only call loadZoomSdkAndJoinMeeting if parameters are present
      this.loadZoomSdkAndJoinMeeting();
    });
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
          this.joinMeeting();
        })
        .catch((error: any) => {
          console.error('Error loading Zoom SDK:', error);
          // Optionally, navigate the user away or provide retry options.
          // Example: this.router.navigate(['/sessions'], { queryParams: { error: 'zoom_sdk_failed' } });
        });
    });
  }

  joinMeeting(): void {
    this.client.join({
      sdkKey: this.sdkKey,
      signature: this.signature,
      meetingNumber: this.meetingNumber,
      userName: this.userName,
      userEmail: this.userEmail, // Optional: email of the user
      password: this.passWord,
      tk: this.registrantToken,
      zak: this.zakToken,
      success: (success: any) => {
        console.log('Joined Zoom meeting successfully:', success);
        // Make the Zoom meeting UI visible if it was hidden
        // document.getElementById('zmmtg-root')!.style.display = 'block';
        console.log('Joined Zoom meeting successfully:', success);
      },
      error: (error: any) => {
        console.error('Error joining Zoom meeting via SDK:', error);
        // Display a user-friendly error message.
        // TODO: Replace with a more sophisticated notification service if available.
        let errorMessage =
          'An unexpected error occurred while trying to join the meeting.';

        // Optionally, navigate the user away or provide retry options.
        // Example: this.router.navigate(['/sessions'], { queryParams: { error: 'zoom_sdk_failed' } });
      },
    });
  }
}

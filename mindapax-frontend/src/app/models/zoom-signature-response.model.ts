export interface ZoomSignatureResponse {
  apiKey: string;
  meetingNumber: string;
  signature: string;
  // Optional: Add userName and userEmail if they are part of the backend response
  // and needed for the ZoomMtg.join() method.
  // userName?: string;
  // userEmail?: string;
}

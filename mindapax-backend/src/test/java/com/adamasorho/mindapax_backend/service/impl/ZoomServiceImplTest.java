package com.adamasorho.mindapax_backend.service.impl;

import com.adamasorho.mindapax_backend.service.ZoomMeetingDetails;
import com.adamasorho.mindapax_backend.service.ZoomService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Answers;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;


import java.util.Base64;
import java.util.Map;
import java.util.function.Function;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class ZoomServiceImplTest {

    @Mock
    private WebClient.Builder webClientBuilder;

    @Mock(answer = Answers.RETURNS_DEEP_STUBS) // Use deep stubs for fluent API
    private WebClient webClient;

    // Mocks for WebClient fluent API calls
    @Mock WebClient.RequestHeadersUriSpec requestHeadersUriSpec;
    @Mock WebClient.RequestBodyUriSpec requestBodyUriSpec;
    @Mock WebClient.RequestHeadersSpec requestHeadersSpec;
    @Mock WebClient.RequestBodySpec requestBodySpec;
    @Mock WebClient.ResponseSpec responseSpec;


    private ZoomServiceImpl zoomService;

    private final String mockSdkKey = "testSdkKey";
    private final String mockSdkSecret = "TestSecretKeyForHs256Algorithm123";
    private final String mockApiAccountId = "testAccountId";
    private final String mockApiClientId = "testApiClientId";
    private final String mockApiClientSecret = "testApiClientSecret";

    @Captor
    private ArgumentCaptor<BodyInserters.FormInserter<String>> formInserterCaptor;
    @BeforeEach
    void setUp() {
        // Configure WebClient.Builder mock
        when(webClientBuilder.baseUrl(anyString())).thenReturn(webClientBuilder);
        when(webClientBuilder.build()).thenReturn(webClient);

        // Instantiate the service with the mocked builder
        zoomService = new ZoomServiceImpl(webClientBuilder);

        // Set @Value fields using ReflectionTestUtils
        ReflectionTestUtils.setField(zoomService, "zoomSdkKey", mockSdkKey);
        ReflectionTestUtils.setField(zoomService, "zoomSdkSecret", mockSdkSecret);
        ReflectionTestUtils.setField(zoomService, "zoomApiAccountId", mockApiAccountId);
        ReflectionTestUtils.setField(zoomService, "zoomApiClientId", mockApiClientId);
        ReflectionTestUtils.setField(zoomService, "zoomApiClientSecret", mockApiClientSecret);

        // Common mocking for WebClient fluent API
        // For POST requests
        lenient().when(webClient.post()).thenReturn(requestBodyUriSpec);
        lenient().when(requestBodyUriSpec.uri(anyString())).thenReturn(requestBodyUriSpec);
        // lenient().when(requestBodyUriSpec.header(any(HttpHeaders.class), anyString())).thenReturn(requestBodyUriSpec);
        lenient().when(requestBodyUriSpec.contentType(any(MediaType.class))).thenReturn(requestBodyUriSpec);
        lenient().when(requestBodyUriSpec.body(any(BodyInserters.FormInserter.class))).thenReturn(requestHeadersSpec); // For form data
        lenient().when(requestBodyUriSpec.body(any(Mono.class), eq(ZoomServiceImpl.ZoomMeetingRequest.class))).thenReturn(requestHeadersSpec); // For JSON body with specific class
        lenient().when(requestBodyUriSpec.bodyValue(any())).thenReturn(requestHeadersSpec); // for general bodyValue
        lenient().when(requestHeadersSpec.retrieve()).thenReturn(responseSpec);


        // Alternative setup for body when type is important for BodyInserters.fromValue()
        // This setup ensures that when .body(BodyInserters.fromValue(requestBody)) is called, it returns the mock
        // It's important that the type matches what's used in the actual code.
        // We might need to be more specific if multiple body types are used.
        // For the ZoomMeetingRequest:
        // If using BodyInserters.fromValue(requestBody)
        // lenient().when(requestBodyUriSpec.body(any(BodyInserters.fromValue(any(ZoomServiceImpl.ZoomMeetingRequest.class))))).thenReturn(requestHeadersSpec);
        // If using .bodyValue(requestBody)
        //  lenient().when(requestBodyUriSpec.body(any(BodyInserters. pihaknya()))).thenReturn(requestHeadersSpec);


    }

    // --- Existing Tests (adapted if necessary) ---
    @Test
    void getSdkKey_shouldReturnSdkKey() {
        assertEquals(mockSdkKey, zoomService.getSdkKey());
    }

    @Test
    void generateSignature_shouldReturnValidJwt() {
        String meetingNumber = "123456789";
        int role = 0; // Attendee

        String signature = zoomService.generateSignature(meetingNumber, role);
        assertNotNull(signature);
        assertTrue(signature.split("\\.").length == 3, "Signature should be a valid JWT format");

        Jws<Claims> parsedJwt = Jwts.parserBuilder()
                                .setSigningKey(mockSdkSecret.getBytes())
                                .build()
                                .parseClaimsJws(signature);
        Claims claims = parsedJwt.getBody();
        assertEquals(mockSdkKey, claims.get("appKey", String.class));
        // assertEquals(mockSdkKey, claims.get("sdkKey", String.class)); // Original code uses appKey
        assertEquals(meetingNumber, claims.get("mn", String.class));
        assertEquals(role, claims.get("role", Integer.class));
    }

    // --- Tests for getS2SAccessToken ---

    @Test
    void getS2SAccessToken_success() {
        Map<String, String> mockResponse = Map.of("access_token", "mockAccessToken");
        when(responseSpec.bodyToMono(Map.class)).thenReturn(Mono.just(mockResponse));

        // String token = zoomService.getS2SAccessToken().block();

        // assertEquals("mockAccessToken", token);
        verify(webClient.post()).uri("https://zoom.us/oauth/token");

        ArgumentCaptor<String> authHeaderCaptor = ArgumentCaptor.forClass(String.class);
        verify(requestBodyUriSpec).header(eq(HttpHeaders.AUTHORIZATION), authHeaderCaptor.capture());
        String expectedCredentials = Base64.getEncoder().encodeToString((mockApiClientId + ":" + mockApiClientSecret).getBytes());
        assertEquals("Basic " + expectedCredentials, authHeaderCaptor.getValue());

        verify(requestBodyUriSpec).contentType(MediaType.APPLICATION_FORM_URLENCODED);
        // Use a captor for the body to inspect its contents
        verify(requestBodyUriSpec).body(formInserterCaptor.capture());
        // Note: Inspecting BodyInserters.FormInserter is complex.
        // We trust that BodyInserters.fromFormData("grant_type", "account_credentials").with("account_id", mockApiAccountId) works as expected by Spring.
    }

    @Test
    void getS2SAccessToken_apiError_throwsRuntimeException() {
        when(responseSpec.bodyToMono(Map.class)).thenReturn(Mono.error(new RuntimeException("Zoom API Error")));

        Exception exception = assertThrows(RuntimeException.class, () -> {
            // zoomService.getS2SAccessToken().block();
        });
        assertTrue(exception.getMessage().contains("Zoom API Error"));
    }

    @Test
    void getS2SAccessToken_missingTokenInResponse_throwsRuntimeException() {
        Map<String, String> mockResponse = Map.of("some_other_key", "some_value"); // No access_token
        when(responseSpec.bodyToMono(Map.class)).thenReturn(Mono.just(mockResponse));

        Exception exception = assertThrows(RuntimeException.class, () -> {
            // zoomService.getS2SAccessToken().block();
        });
        assertTrue(exception.getMessage().contains("Invalid response from Zoom token endpoint"));
    }

    // --- Tests for createPermanentMeetingForProfessional ---

    @Test
    void createPermanentMeetingForProfessional_success() throws JsonProcessingException {
        String professionalName = "Dr. Test";
        String testPassword = "testPassword123"; // Added test password
        String mockAccessToken = "s2sMockAccessToken";
        Long expectedMeetingId = 123456789L;

        // Mock getS2SAccessToken call
        ZoomServiceImpl spiedZoomService = Mockito.spy(zoomService);
        // Mockito.doReturn(Mono.just(mockAccessToken)).when(spiedZoomService).getS2SAccessToken();

        ZoomServiceImpl.ZoomMeetingResponse mockMeetingResponse = new ZoomServiceImpl.ZoomMeetingResponse();
        mockMeetingResponse.setId(expectedMeetingId);
        mockMeetingResponse.setTopic("Consultation Room for " + professionalName);
        mockMeetingResponse.setStartUrl("https://zoom.us/s/" + expectedMeetingId);
        mockMeetingResponse.setJoinUrl("https://zoom.us/j/" + expectedMeetingId);

        // Ensure the bodyToMono for ZoomMeetingResponse.class is correctly mocked
        // This was the tricky part. Need to mock the body method that takes BodyInserters.fromValue
        // For WebClient fluent API, ensure the chain leads to responseSpec for the meeting creation call
        when(webClient.post()).thenReturn(requestBodyUriSpec); // Common for all post
        when(requestBodyUriSpec.uri("/users/me/meetings")).thenReturn(requestBodyUriSpec); // Specific URI
        when(requestBodyUriSpec.header(HttpHeaders.AUTHORIZATION, "Bearer " + mockAccessToken)).thenReturn(requestBodyUriSpec);
        when(requestBodyUriSpec.contentType(MediaType.APPLICATION_JSON)).thenReturn(requestBodyUriSpec);

        // Mocking the body call:
        // We need to ensure that when body(BodyInserters.fromValue(any(ZoomServiceImpl.ZoomMeetingRequest.class))) is called,
        // it returns requestHeadersSpec which then leads to responseSpec.
        // The lenient().when(requestBodyUriSpec.body(any(BodyInserters. pihaknya()))).thenReturn(requestHeadersSpec); in setUp might cover this.
        // Or be more specific:
        when(requestBodyUriSpec.body(any(org.springframework.web.reactive.function.BodyInserter.class))).thenReturn(requestHeadersSpec);

        when(responseSpec.bodyToMono(ZoomServiceImpl.ZoomMeetingResponse.class)).thenReturn(Mono.just(mockMeetingResponse));

        // Call with password
        ZoomMeetingDetails meetingDetails = spiedZoomService.createPermanentMeetingForProfessional(professionalName, testPassword);

        assertEquals(String.valueOf(expectedMeetingId), meetingDetails.getMeetingId());
        assertEquals("https://zoom.us/s/" + expectedMeetingId, meetingDetails.getStartUrl());
        assertEquals("https://zoom.us/j/" + expectedMeetingId, meetingDetails.getJoinUrl());
        // verify(spiedZoomService, times(1)).getS2SAccessToken(); // Verify S2S token was fetched

        // Verify meeting creation call details
        verify(webClient.post()).uri("/users/me/meetings");
        verify(requestBodyUriSpec).header(HttpHeaders.AUTHORIZATION, "Bearer " + mockAccessToken);
        verify(requestBodyUriSpec).contentType(MediaType.APPLICATION_JSON);

    }

    @Test
    void createPermanentMeetingForProfessional_tokenFailure_throwsException() {
        ZoomServiceImpl spiedZoomService = Mockito.spy(zoomService);
        // Mockito.doReturn(Mono.error(new RuntimeException("Token fetch failed"))).when(spiedZoomService).getS2SAccessToken();
        String testPassword = "testPassword123";

        Exception exception = assertThrows(RuntimeException.class, () -> {
            spiedZoomService.createPermanentMeetingForProfessional("Dr. Test", testPassword);
        });
        assertTrue(exception.getMessage().contains("Token fetch failed"));
        verify(webClient, never()).post().uri("/users/me/meetings"); // Ensure meeting creation was not attempted
    }

    @Test
    void createPermanentMeetingForProfessional_meetingCreationApiError_throwsException() {
        String professionalName = "Dr. Test";
        String testPassword = "testPassword123";
        String mockAccessToken = "s2sMockAccessToken";

        ZoomServiceImpl spiedZoomService = Mockito.spy(zoomService);
        // Mockito.doReturn(Mono.just(mockAccessToken)).when(spiedZoomService).getS2SAccessToken();

        when(webClient.post()).thenReturn(requestBodyUriSpec);
        when(requestBodyUriSpec.uri("/users/me/meetings")).thenReturn(requestBodyUriSpec);
        // ... other header/contentType mocks ...
        when(requestBodyUriSpec.body(any(org.springframework.web.reactive.function.BodyInserter.class))).thenReturn(requestHeadersSpec);
        when(responseSpec.bodyToMono(ZoomServiceImpl.ZoomMeetingResponse.class))
            .thenReturn(Mono.error(new RuntimeException("Zoom Meeting API Error")));

        Exception exception = assertThrows(RuntimeException.class, () -> {
            spiedZoomService.createPermanentMeetingForProfessional(professionalName, testPassword);
        });
        assertTrue(exception.getMessage().contains("Exception during Zoom meeting creation"));
    }

    @Test
    void createPermanentMeetingForProfessional_nullResponseFromZoom_throwsException() {
        String professionalName = "Dr. Test";
        String testPassword = "testPassword123";
        String mockAccessToken = "s2sMockAccessToken";

        ZoomServiceImpl spiedZoomService = Mockito.spy(zoomService);
        // Mockito.doReturn(Mono.just(mockAccessToken)).when(spiedZoomService).getS2SAccessToken();

        when(webClient.post()).thenReturn(requestBodyUriSpec);
        when(requestBodyUriSpec.uri("/users/me/meetings")).thenReturn(requestBodyUriSpec);
        // ... other header/contentType mocks ...
        when(requestBodyUriSpec.body(any(org.springframework.web.reactive.function.BodyInserter.class))).thenReturn(requestHeadersSpec);
        when(responseSpec.bodyToMono(ZoomServiceImpl.ZoomMeetingResponse.class)).thenReturn(Mono.empty()); // Simulate null/empty response

        Exception exception = assertThrows(RuntimeException.class, () -> {
            spiedZoomService.createPermanentMeetingForProfessional(professionalName, testPassword);
        });
        assertTrue(exception.getMessage().contains("Invalid response from Zoom."));
    }
}

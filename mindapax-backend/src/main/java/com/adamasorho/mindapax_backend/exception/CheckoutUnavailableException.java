package com.adamasorho.mindapax_backend.exception;

public class CheckoutUnavailableException extends RuntimeException {
    private static final String DEFAULT_CODE = "CHECKOUT_UNAVAILABLE";
    private final String code;

    public CheckoutUnavailableException(String message) {
        super(message);
        this.code = DEFAULT_CODE;
    }

    public CheckoutUnavailableException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}


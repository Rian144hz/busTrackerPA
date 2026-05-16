package br.com.rastreamento.exceptions;

import org.springframework.http.HttpStatus;

public class BustrackerException extends RuntimeException {

    private final HttpStatus status;

    public BustrackerException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}

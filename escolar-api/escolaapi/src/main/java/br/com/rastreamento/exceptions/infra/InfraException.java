package br.com.rastreamento.exceptions.infra;

import br.com.rastreamento.exceptions.BustrackerException;
import org.springframework.http.HttpStatus;

public class InfraException extends BustrackerException {
    public InfraException(String mensagem) {
        super(mensagem, HttpStatus.SERVICE_UNAVAILABLE); // 503
    }
}
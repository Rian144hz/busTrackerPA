package br.com.rastreamento.exceptions.rastreamento;

import br.com.rastreamento.exceptions.BustrackerException;
import org.springframework.http.HttpStatus;

public class RastreamentoException extends BustrackerException {
    public RastreamentoException(String message) {
        super(message, HttpStatus.UNPROCESSABLE_ENTITY);
    }
}

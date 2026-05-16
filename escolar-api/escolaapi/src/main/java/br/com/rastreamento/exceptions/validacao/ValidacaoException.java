package br.com.rastreamento.exceptions.validacao;

import br.com.rastreamento.exceptions.BustrackerException;
import org.springframework.http.HttpStatus;

public class ValidacaoException extends BustrackerException {
    public ValidacaoException(String message) {
        super(message,HttpStatus.BAD_REQUEST);
    }
}

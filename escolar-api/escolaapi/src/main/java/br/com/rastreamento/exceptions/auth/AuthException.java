package br.com.rastreamento.exceptions.auth;

import br.com.rastreamento.exceptions.BustrackerException;
import org.springframework.http.HttpStatus;

public class AuthException extends BustrackerException {
  public AuthException(String mensagem) {
    super(mensagem, HttpStatus.UNAUTHORIZED);
  }
}
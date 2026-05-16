package br.com.rastreamento.exceptions.auth;

public class CredenciaisInvalidasException extends AuthException {
    public CredenciaisInvalidasException() {
        super("CPF, nome ou placa não conferem.");
    }
}

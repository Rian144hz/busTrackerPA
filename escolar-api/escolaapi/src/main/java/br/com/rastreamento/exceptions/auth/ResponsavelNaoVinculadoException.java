package br.com.rastreamento.exceptions.auth;

public class ResponsavelNaoVinculadoException extends AuthException {
    public ResponsavelNaoVinculadoException(String nome) {
        super("Responsável "+nome+" não está vinculado com essa matrícula.");
    }
}

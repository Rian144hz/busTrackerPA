package br.com.rastreamento.exceptions.auth;

public class MotoristaInativoException extends AuthException {
    public MotoristaInativoException(String cpf) {
        super("Motorista com o CPF "+cpf+" está inativo no sistema.");
    }
}

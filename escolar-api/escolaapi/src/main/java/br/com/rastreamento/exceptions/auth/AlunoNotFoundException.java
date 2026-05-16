package br.com.rastreamento.exceptions.auth;

public class AlunoNotFoundException extends AuthException {
    public AlunoNotFoundException(String matricula) {
        super("Aluno com matŕicula "+matricula+ "não encontrado ou inativo no sistema.");
    }
}

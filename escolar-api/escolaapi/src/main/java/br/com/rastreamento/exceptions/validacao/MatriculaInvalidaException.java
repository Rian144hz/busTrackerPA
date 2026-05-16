package br.com.rastreamento.exceptions.validacao;

public class MatriculaInvalidaException extends ValidacaoException {
    public MatriculaInvalidaException(String matricula) {
        super("Matrícula inválida. "+matricula);
    }
}

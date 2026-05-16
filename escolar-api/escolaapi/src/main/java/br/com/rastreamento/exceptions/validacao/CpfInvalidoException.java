package br.com.rastreamento.exceptions.validacao;

public class CpfInvalidoException extends ValidacaoException {
    public CpfInvalidoException(String cpf) {
        super("CPF inválido. "+cpf);
    }
}

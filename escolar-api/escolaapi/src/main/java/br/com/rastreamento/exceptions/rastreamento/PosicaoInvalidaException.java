package br.com.rastreamento.exceptions.rastreamento;

public class PosicaoInvalidaException extends RastreamentoException {
    public PosicaoInvalidaException(String motivo) {
        super("Posição inválida. "+motivo);
    }
}

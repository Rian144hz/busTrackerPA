package br.com.rastreamento.exceptions.validacao;

public class PlacaInvalidaException extends ValidacaoException {
    public PlacaInvalidaException(String placa) {
        super("Placa fora do formato aceito: "+placa);
    }
}

package br.com.rastreamento.exceptions.rastreamento;

public class CoordenadasForaDoBrasilException extends RastreamentoException {
    public CoordenadasForaDoBrasilException(Double lat,double lon) {
        super("Coordenadas fora do território nacional. "+lat+","+lon);
    }
}

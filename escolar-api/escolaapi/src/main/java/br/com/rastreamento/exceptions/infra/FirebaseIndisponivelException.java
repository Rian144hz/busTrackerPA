package br.com.rastreamento.exceptions.infra;

public class FirebaseIndisponivelException extends InfraException {
    public FirebaseIndisponivelException(String detalhe) {
        super("Serviço de notificações indisponível. Posição salva normalmente. Detalhe: " + detalhe);
    }
}

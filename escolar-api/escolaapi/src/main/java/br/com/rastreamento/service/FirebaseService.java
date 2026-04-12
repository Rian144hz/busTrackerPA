package br.com.rastreamento.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

/**
 * Service responsavel pelo envio de notificacoes push via Firebase Cloud Messaging.
 */
@Service
public class FirebaseService {

    /**
     * Envia notificacao de atraso para o topico configurado.
     *
     * @param placa placa do veiculo atrasado
     * @param motivo descricao do motivo do atraso
     */
    public void enviarNotificacaoAtraso(String placa, String motivo) {
        try {
            Notification notification = Notification.builder()
                    .setTitle("Alerta BusTracker")
                    .setBody("Veiculo " + placa + " relatou: " + motivo)
                    .build();

            Message message = Message.builder()
                    .setTopic("onibus_paulo_afonso")
                    .setNotification(notification)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("Notificacao enviada: " + response);

        } catch (Exception e) {
            System.err.println("Erro ao enviar notificacao: " + e.getMessage());
            e.printStackTrace();
        }
    }
}

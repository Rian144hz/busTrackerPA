package br.com.rastreamento.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

@Service
public class FirebaseService {

    public void enviarNotificacaoAtraso(String placa, String motivo) {
        try {
            // Criando a notificação que aparece no topo do celular
            Notification notification = Notification.builder()
                    .setTitle("⚠️ Alerta BusTracker")
                    .setBody("Veículo " + placa + " relatou: " + motivo)
                    .build();

            // Montando a mensagem para o tópico
            Message message = Message.builder()
                    .setTopic("onibus_paulo_afonso")
                    .setNotification(notification)
                    .build();

            // Enviando de fato
            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("✅ Notificação enviada com sucesso: " + response);

        } catch (Exception e) {
            System.err.println("❌ Erro ao enviar para o Firebase: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
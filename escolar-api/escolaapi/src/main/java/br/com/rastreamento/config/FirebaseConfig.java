package br.com.rastreamento.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Configuracao de inicializacao do Firebase Cloud Messaging.
 * Executada automaticamente apos a construcao do bean.
 */
@Configuration
public class FirebaseConfig {

    /**
     * Inicializa o Firebase com as credenciais do serviceAccountKey.json.
     * Executado automaticamente apos a injecao de dependencias.
     */
    @PostConstruct
    public void init() {
        try {
            InputStream serviceAccount = null;

            serviceAccount = getClass().getClassLoader().getResourceAsStream("serviceAccountKey.json");

            if (serviceAccount == null) {
                File file = new File("src/main/resources/serviceAccountKey.json");
                if (file.exists()) {
                    serviceAccount = new FileInputStream(file);
                }
            }

            if (serviceAccount == null) {
                throw new IOException("Arquivo serviceAccountKey.json nao encontrado.");
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("Firebase inicializado com sucesso");
            }
        } catch (IOException e) {
            System.err.println("Erro ao inicializar Firebase: " + e.getMessage());
            System.out.println("Diretorio atual: " + System.getProperty("user.dir"));
        }
    }
}

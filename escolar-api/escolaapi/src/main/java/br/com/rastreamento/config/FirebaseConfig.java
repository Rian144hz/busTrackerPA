package br.com.rastreamento.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void init() {
        try {
            InputStream serviceAccount = null;

            // Tentativa 1: ClassPath (O padrão)
            serviceAccount = getClass().getClassLoader().getResourceAsStream("serviceAccountKey.json");

            // Tentativa 2: Se a 1 falhar, tenta caminho direto no disco
            if (serviceAccount == null) {
                File file = new File("src/main/resources/serviceAccountKey.json");
                if (file.exists()) {
                    serviceAccount = new FileInputStream(file);
                }
            }

            if (serviceAccount == null) {
                throw new IOException("Arquivo não encontrado em nenhum dos caminhos.");
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("🚀 Firebase inicializado com sucesso!");
            }
        } catch (IOException e) {
            System.err.println("❌ ERRO CRÍTICO: " + e.getMessage());
            // Esse comando abaixo vai mostrar a pasta onde o Java está tentando rodar
            System.out.println("Diretório atual do Java: " + System.getProperty("user.dir"));
        }
    }
}
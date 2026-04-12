package br.com.rastreamento;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Classe principal de inicializacao da aplicacao Spring Boot.
 * Responsavel por iniciar o contexto da aplicacao e o servidor embutido.
 *
 * @SpringBootApplication combina @Configuration, @EnableAutoConfiguration e @ComponentScan
 */
@SpringBootApplication
public class EscolaapiApplication {

    /**
     * Metodo principal que inicia a aplicacao.
     *
     * @param args argumentos de linha de comando
     */
    public static void main(String[] args) {
        SpringApplication.run(EscolaapiApplication.class, args);
    }

}

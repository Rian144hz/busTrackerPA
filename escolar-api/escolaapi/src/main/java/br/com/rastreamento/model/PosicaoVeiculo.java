package br.com.rastreamento.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entidade JPA representando um registro de posicao GPS de um veiculo.
 * Mapeada para a tabela "atrasos".
 */
@Entity
@Table(name = "atrasos")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PosicaoVeiculo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long cpf;

    @Column(nullable = false, length = 100)
    private String nome;

    @Column(name = "placa_veiculo", nullable = false, length = 10)
    private String placaVeiculo;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(precision = 5, scale = 2)
    private BigDecimal velocidade;

    @Column(columnDefinition = "TEXT")
    private String motivoAtraso;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    /**
     * Define o timestamp automaticamente se nao informado.
     */
    @PrePersist
    public void prePersist() {
        if (this.timestamp == null) {
            this.timestamp = LocalDateTime.now();
        }
    }
}

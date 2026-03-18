package br.com.rastreamento.escolar.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entidade JPA que mapeia a tabela 'posicoes'.
 * Representa um registro de localização enviado pelo app do motorista.
 */
@Entity
@Table(
        name = "posicoes",
        indexes = {
                @Index(name = "idx_posicoes_placa_timestamp",
                        columnList = "placa_veiculo, timestamp DESC")
        }
)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PosicaoVeiculo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "placa_veiculo", nullable = false, length = 10)
    private String placaVeiculo;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(precision = 5, scale = 2)
    private BigDecimal velocidade;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    /** Garante que o timestamp seja preenchido antes de persistir. */
    @PrePersist
    public void prePersist() {
        if (this.timestamp == null) {
            this.timestamp = LocalDateTime.now();
        }
    }
}
package br.com.rastreamento.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidade JPA representando um motorista do transporte escolar.
 * Mapeada para a tabela "motoristas".
 */
@Entity
@Table(name = "motoristas")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Motorista {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 14)
    private String cpf;

    @Column(nullable = false, length = 100)
    private String nome;

    @Column(name = "placa_veiculo", nullable = false, unique = true, length = 10)
    private String placaVeiculo;

    @Column(nullable = false)
    @Builder.Default
    private Boolean ativo = true;

    @Column(name = "criado_em", nullable = false)
    private LocalDateTime criadoEm;

    /**
     * Preenche campos automaticamente antes da persistencia.
     */
    @PrePersist
    public void prePersist() {
        if (this.criadoEm == null) this.criadoEm = LocalDateTime.now();
        if (this.ativo == null) this.ativo = true;
    }
}

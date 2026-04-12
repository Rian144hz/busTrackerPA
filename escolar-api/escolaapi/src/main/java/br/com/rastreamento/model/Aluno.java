package br.com.rastreamento.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidade JPA representando um aluno matriculado no sistema.
 * Mapeada para a tabela "alunos".
 */
@Entity
@Table(name = "alunos")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Aluno {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 20)
    private String matricula;

    @Column(name = "nome_aluno", nullable = false, length = 100)
    private String nomeAluno;

    @Column(name = "nome_responsavel", nullable = false, length = 100)
    private String nomeResponsavel;

    @Column(name = "placa_veiculo", nullable = false, length = 10)
    private String placaVeiculo;

    @Column(nullable = false)
    private Boolean ativo = true;

    @Column(name = "criado_em", nullable = false)
    private LocalDateTime criadoEm;

    /**
     * Preenche campos automaticamente antes da persistencia.
     * Executado pelo JPA antes do INSERT.
     */
    @PrePersist
    public void prePersist() {
        if (this.criadoEm == null) this.criadoEm = LocalDateTime.now();
        if (this.ativo == null) this.ativo = true;
    }
}

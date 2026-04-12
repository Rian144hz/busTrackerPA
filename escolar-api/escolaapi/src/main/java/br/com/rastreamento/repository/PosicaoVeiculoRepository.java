package br.com.rastreamento.repository;

import br.com.rastreamento.model.PosicaoVeiculo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio para operacoes de persistencia da entidade PosicaoVeiculo.
 */
@Repository
public interface PosicaoVeiculoRepository
        extends JpaRepository<PosicaoVeiculo, Long> {

    /**
     * Busca a posicao mais recente de um veiculo pela placa.
     *
     * @param placa placa do veiculo
     * @return Optional com a posicao mais recente
     */
    @Query("""
        SELECT p FROM PosicaoVeiculo p
        WHERE p.placaVeiculo = :placa
        ORDER BY p.timestamp DESC
        LIMIT 1
    """)
    Optional<PosicaoVeiculo> findUltimaPosicaoByPlaca(
            @Param("placa") String placa
    );

    /**
     * Lista registros com motivo de atraso, ordenados do mais recente.
     *
     * @return lista de posicoes com atraso
     */
    List<PosicaoVeiculo> findByMotivoAtrasoIsNotNullOrderByTimestampDesc();
}

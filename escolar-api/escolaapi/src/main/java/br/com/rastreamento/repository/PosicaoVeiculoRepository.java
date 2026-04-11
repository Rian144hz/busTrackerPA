package br.com.rastreamento.repository;

import br.com.rastreamento.model.PosicaoVeiculo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PosicaoVeiculoRepository
        extends JpaRepository<PosicaoVeiculo, Long> {

    /**
     * Busca a posição mais recente de um veículo pela placa.
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
     * Busca todos os registros que possuem motivo de atraso,
     * ordenando pelos mais recentes.
     */
    List<PosicaoVeiculo> findByMotivoAtrasoIsNotNullOrderByTimestampDesc();
}
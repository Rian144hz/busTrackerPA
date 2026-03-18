package br.com.rastreamento.repository;

import br.com.rastreamento.escolar.model.PosicaoVeiculo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PosicaoVeiculoRepository
        extends JpaRepository<PosicaoVeiculo, Long> {

    /**
     * Busca a posição mais recente de um veículo pela placa,
     * ordenando pelo timestamp em ordem decrescente e pegando o primeiro.
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
}
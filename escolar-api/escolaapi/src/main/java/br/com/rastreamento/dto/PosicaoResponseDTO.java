package br.com.rastreamento.dto;
import java.math.BigDecimal;
import java.time.LocalDateTime;


/**
 * DTO de response para consulta de posicao.
 * Retornado nas consultas de rastreamento.
 *
 * @param id identificador do registro
 * @param cpf CPF do motorista
 * @param nome nome do motorista
 * @param placaVeiculo placa do veiculo
 * @param latitude coordenada geografica Y
 * @param longitude coordenada geografica X
 * @param velocidade velocidade em km/h
 * @param timestamp data/hora do registro
 */
public record PosicaoResponseDTO(
        Long id,
        String cpf,
        String nome,
        String placaVeiculo,
        BigDecimal latitude,
        BigDecimal longitude,
        BigDecimal velocidade,
        LocalDateTime timestamp
) {}

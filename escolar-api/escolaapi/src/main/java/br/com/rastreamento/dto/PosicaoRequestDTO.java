package br.com.rastreamento.dto;

import java.math.BigDecimal;

/**
 * DTO de request para envio de posicao GPS.
 * Recebido do app do motorista.
 *
 * @param id identificador do registro (null para novos)
 * @param cpf CPF do motorista
 * @param nome nome do motorista
 * @param placaVeiculo placa do veiculo
 * @param latitude coordenada geografica Y
 * @param longitude coordenada geografica X
 * @param velocidade velocidade em km/h
 * @param motivoAtraso descricao do atraso (opcional)
 */
public record PosicaoRequestDTO(
        Long id,
        long cpf,
        String nome,
        String placaVeiculo,
        BigDecimal latitude,
        BigDecimal longitude,
        BigDecimal velocidade,
        String motivoAtraso
) {}

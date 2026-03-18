package br.com.rastreamento.dto;
import java.math.BigDecimal;
import java.time.LocalDateTime;


public record PosicaoResponseDTO(
        Long id,
        String placaVeiculo,
        BigDecimal latitude,
        BigDecimal longitude,
        BigDecimal velocidade,
        LocalDateTime timestamp
) {}
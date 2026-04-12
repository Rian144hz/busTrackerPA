package br.com.rastreamento.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// ── Request DTO (recebido do App Flutter) ─────────────────────
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


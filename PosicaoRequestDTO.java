package br.com.rastreamento.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// ── Request DTO (recebido do App Flutter) ─────────────────────
public record PosicaoRequestDTO(
        String placaVeiculo,
        BigDecimal latitude,
        BigDecimal longitude,
        BigDecimal velocidade   // opcional; app pode enviar null
) {}


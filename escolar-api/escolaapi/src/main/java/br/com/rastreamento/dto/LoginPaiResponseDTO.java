package br.com.rastreamento.dto;

public record LoginPaiResponseDTO(
        Long id,
        String nomeAluno,
        String nomeResponsavel,
        String matricula,
        String placaVeiculo
) {}
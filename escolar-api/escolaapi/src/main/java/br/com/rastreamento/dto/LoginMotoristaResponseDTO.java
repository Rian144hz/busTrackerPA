package br.com.rastreamento.dto;

public record LoginMotoristaResponseDTO(
        Long id,
        String nome,
        String cpf,
        String placaVeiculo
) {}
package br.com.rastreamento.dto;

public record LoginMotoristaRequestDTO(
        String cpf,
        String nome,
        String placaVeiculo
) {}

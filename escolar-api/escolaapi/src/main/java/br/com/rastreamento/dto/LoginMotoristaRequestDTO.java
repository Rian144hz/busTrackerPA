package br.com.rastreamento.dto;

/**
 * DTO de request para login do motorista.
 * Contem as credenciais necessarias para autenticacao.
 *
 * @param cpf CPF do motorista
 * @param nome nome completo do motorista
 * @param placaVeiculo placa do veiculo vinculado
 */
public record LoginMotoristaRequestDTO(
        String cpf,
        String nome,
        String placaVeiculo
) {}

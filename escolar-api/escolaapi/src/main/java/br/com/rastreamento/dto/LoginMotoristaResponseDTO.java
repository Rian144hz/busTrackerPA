package br.com.rastreamento.dto;

/**
 * DTO de response para login do motorista.
 * Retornado quando a autenticacao e bem-sucedida.
 *
 * @param id identificador interno do motorista
 * @param nome nome do motorista
 * @param cpf CPF do motorista
 * @param placaVeiculo placa do veiculo vinculado
 */
public record LoginMotoristaResponseDTO(
        Long id,
        String nome,
        String cpf,
        String placaVeiculo
) {}

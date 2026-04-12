package br.com.rastreamento.dto;

/**
 * DTO de response para login do responsavel.
 * Retornado quando a autenticacao e bem-sucedida.
 *
 * @param id identificador interno do aluno
 * @param nomeAluno nome do aluno
 * @param nomeResponsavel nome do responsavel
 * @param matricula matricula do aluno
 * @param placaVeiculo placa do veiculo do aluno
 */
public record LoginPaiResponseDTO(
        Long id,
        String nomeAluno,
        String nomeResponsavel,
        String matricula,
        String placaVeiculo
) {}

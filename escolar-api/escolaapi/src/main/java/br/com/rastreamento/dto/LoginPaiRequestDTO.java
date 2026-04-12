package br.com.rastreamento.dto;

/**
 * DTO de request para login do responsavel.
 * Contem as credenciais necessarias para autenticacao.
 *
 * @param matricula matricula do aluno
 * @param nomeResponsavel nome do responsavel cadastrado
 */
public record LoginPaiRequestDTO(
        String matricula,
        String nomeResponsavel
) {}

package br.com.rastreamento.repository;

import br.com.rastreamento.model.Motorista;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repositorio para operacoes de persistencia da entidade Motorista.
 */
@Repository
public interface MotoristaRepository extends JpaRepository<Motorista, Long> {

    /**
     * Busca motorista ativo pelo CPF.
     *
     * @param cpf CPF do motorista
     * @param ativo status ativo/inativo
     * @return Optional com o motorista encontrado
     */
    Optional<Motorista> findByCpfAndAtivo(String cpf, Boolean ativo);
}

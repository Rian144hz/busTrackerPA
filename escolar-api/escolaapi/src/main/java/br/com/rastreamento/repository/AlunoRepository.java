package br.com.rastreamento.repository;

import br.com.rastreamento.model.Aluno;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repositorio para operacoes de persistencia da entidade Aluno.
 */
@Repository
public interface AlunoRepository extends JpaRepository<Aluno, Long> {

    /**
     * Busca aluno ativo pela matricula.
     *
     * @param matricula matricula do aluno
     * @param ativo status ativo/inativo
     * @return Optional com o aluno encontrado
     */
    Optional<Aluno> findByMatriculaAndAtivo(String matricula, Boolean ativo);
}

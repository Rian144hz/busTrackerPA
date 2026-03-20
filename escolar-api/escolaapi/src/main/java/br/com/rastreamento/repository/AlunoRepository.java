package br.com.rastreamento.repository;

import br.com.rastreamento.model.Aluno;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface AlunoRepository extends JpaRepository<Aluno, Long> {

    Optional<Aluno> findByMatriculaAndAtivo(String matricula, Boolean ativo);
}
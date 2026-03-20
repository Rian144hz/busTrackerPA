package br.com.rastreamento.repository;

import br.com.rastreamento.model.Motorista;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface MotoristaRepository extends JpaRepository<Motorista, Long> {

    Optional<Motorista> findByCpfAndAtivo(String cpf, Boolean ativo);
}
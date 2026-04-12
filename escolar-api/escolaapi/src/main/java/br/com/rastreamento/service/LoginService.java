package br.com.rastreamento.service;

import br.com.rastreamento.dto.LoginMotoristaRequestDTO;
import br.com.rastreamento.dto.LoginMotoristaResponseDTO;
import br.com.rastreamento.dto.LoginPaiRequestDTO;
import br.com.rastreamento.dto.LoginPaiResponseDTO;
import br.com.rastreamento.repository.AlunoRepository;
import br.com.rastreamento.repository.MotoristaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Service responsavel pela logica de autenticacao.
 * Valida credenciais de pais e motoristas.
 */
@Service
@RequiredArgsConstructor
public class LoginService {

    private final AlunoRepository alunoRepository;
    private final MotoristaRepository motoristaRepository;

    /**
     * Valida credenciais do responsavel e retorna dados do aluno.
     *
     * @param dto credenciais de login (matricula e nome do responsavel)
     * @return Optional com dados do aluno se valido, ou empty se invalido
     */
    public Optional<LoginPaiResponseDTO> loginPai(LoginPaiRequestDTO dto) {
        return alunoRepository
                .findByMatriculaAndAtivo(dto.matricula().trim(), true)
                .filter(a -> a.getNomeResponsavel()
                        .equalsIgnoreCase(dto.nomeResponsavel().trim()))
                .map(a -> new LoginPaiResponseDTO(
                        a.getId(),
                        a.getNomeAluno(),
                        a.getNomeResponsavel(),
                        a.getMatricula(),
                        a.getPlacaVeiculo()
                ));
    }

    /**
     * Valida credenciais do motorista.
     * Verifica CPF, nome e placa do veiculo.
     *
     * @param dto credenciais de login (cpf, nome e placa)
     * @return Optional com dados do motorista se valido, ou empty se invalido
     */
    public Optional<LoginMotoristaResponseDTO> loginMotorista(
            LoginMotoristaRequestDTO dto) {

        return motoristaRepository
                .findByCpfAndAtivo(dto.cpf().trim(), true)
                .filter(m -> m.getNome()
                        .equalsIgnoreCase(dto.nome().trim()))
                .filter(m -> m.getPlacaVeiculo()
                        .equalsIgnoreCase(dto.placaVeiculo().trim()))
                .map(m -> new LoginMotoristaResponseDTO(
                        m.getId(),
                        m.getNome(),
                        m.getCpf(),
                        m.getPlacaVeiculo()
                ));
    }
}

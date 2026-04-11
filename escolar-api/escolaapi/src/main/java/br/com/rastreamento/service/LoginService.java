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

@Service
@RequiredArgsConstructor
public class LoginService {

    private final AlunoRepository alunoRepository;

    /**
     * Valida matrícula + nome do responsável.
     * Retorna os dados do aluno se válido, empty se inválido.
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
    

    private final MotoristaRepository motoristaRepository;

    /**
     * Valida CPF + nome + placa do motorista.
     * Retorna os dados do motorista se válido, empty se inválido.
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
package br.com.rastreamento.service;

import br.com.rastreamento.dto.LoginMotoristaRequestDTO;
import br.com.rastreamento.dto.LoginMotoristaResponseDTO;
import br.com.rastreamento.dto.LoginPaiRequestDTO;
import br.com.rastreamento.dto.LoginPaiResponseDTO;
import br.com.rastreamento.exceptions.auth.AlunoNotFoundException;
import br.com.rastreamento.exceptions.auth.CredenciaisInvalidasException;
import br.com.rastreamento.exceptions.auth.MotoristaInativoException;
import br.com.rastreamento.exceptions.auth.ResponsavelNaoVinculadoException;
import br.com.rastreamento.model.Aluno;
import br.com.rastreamento.model.Motorista;
import br.com.rastreamento.repository.AlunoRepository;
import br.com.rastreamento.repository.MotoristaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class LoginService {

    private final AlunoRepository alunoRepository;
    private final MotoristaRepository motoristaRepository;

    public LoginMotoristaResponseDTO loginMotorista(LoginMotoristaRequestDTO dto) {


        Motorista motorista = motoristaRepository
                .findByCpf(dto.cpf().trim())
                .orElseThrow(CredenciaisInvalidasException::new);


        if (!motorista.getAtivo()) {
            throw new MotoristaInativoException(dto.cpf());
        }


        boolean nomeOk  = motorista.getNome().equalsIgnoreCase(dto.nome().trim());
        boolean placaOk = motorista.getPlacaVeiculo().equalsIgnoreCase(dto.placaVeiculo().trim());

        if (!nomeOk || !placaOk) {
            throw new CredenciaisInvalidasException();
        }

        return new LoginMotoristaResponseDTO(
                motorista.getId(),
                motorista.getNome(),
                motorista.getCpf(),
                motorista.getPlacaVeiculo()
        );
    }

    public LoginPaiResponseDTO loginPai(LoginPaiRequestDTO dto) {


        Aluno aluno = alunoRepository
                .findByMatricula(dto.matricula().trim())
                .orElseThrow(CredenciaisInvalidasException::new);


        if (!aluno.getAtivo()) {
            throw new AlunoNotFoundException(dto.matricula());
        }


        if (!aluno.getNomeResponsavel().equalsIgnoreCase(dto.nomeResponsavel().trim())) {
            throw new ResponsavelNaoVinculadoException(dto.nomeResponsavel());
        }

        return new LoginPaiResponseDTO(
                aluno.getId(),
                aluno.getNomeAluno(),
                aluno.getNomeResponsavel(),
                aluno.getMatricula(),
                aluno.getPlacaVeiculo()
        );
    }
}
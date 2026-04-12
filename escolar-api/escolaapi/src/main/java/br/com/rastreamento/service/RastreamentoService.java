package br.com.rastreamento.service;

import br.com.rastreamento.dto.PosicaoRequestDTO;
import br.com.rastreamento.dto.PosicaoResponseDTO;
import br.com.rastreamento.model.PosicaoVeiculo;
import br.com.rastreamento.repository.PosicaoVeiculoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RastreamentoService {

    private final PosicaoVeiculoRepository repository;
    private final FirebaseService firebaseService;

    public PosicaoResponseDTO salvarPosicao(PosicaoRequestDTO dto) {
        // 1. Converte DTO para a Model
        PosicaoVeiculo entidade = PosicaoVeiculo.builder()
                .cpf(dto.cpf())
                .nome(dto.nome())
                .placaVeiculo(dto.placaVeiculo())
                .latitude(dto.latitude())
                .longitude(dto.longitude())
                .velocidade(dto.velocidade())
                .motivoAtraso(dto.motivoAtraso())
                .build();

        // 2. Salva no Postgres (Tabela atrasos)
        PosicaoVeiculo salvo = repository.save(entidade);

        // 3. Dispara Notificação se houver motivo
        if (dto.motivoAtraso() != null && !dto.motivoAtraso().isBlank()) {
            firebaseService.enviarNotificacaoAtraso(dto.placaVeiculo(), dto.motivoAtraso());
        }

        return toResponse(salvo);
    }

    public Optional<PosicaoResponseDTO> buscarUltimaPosicao(String placa) {
        return repository.findUltimaPosicaoByPlaca(placa).map(this::toResponse);
    }

    private PosicaoResponseDTO toResponse(PosicaoVeiculo p) {
        return new PosicaoResponseDTO(
                p.getId(), p.getCpf(), p.getNome(), p.getPlacaVeiculo(),
                p.getLatitude(), p.getLongitude(), p.getVelocidade(), p.getTimestamp()
        );
    }
    public List<PosicaoResponseDTO> listarAtrasos() {
        return repository.findByMotivoAtrasoIsNotNullOrderByTimestampDesc()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }
}
package br.com.rastreamento.service;

import br.com.rastreamento.dto.PosicaoRequestDTO;
import br.com.rastreamento.dto.PosicaoResponseDTO;
import br.com.rastreamento.escolar.model.PosicaoVeiculo;
import br.com.rastreamento.repository.PosicaoVeiculoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class RastreamentoService {

    private final PosicaoVeiculoRepository repository;

    /** Persiste a nova posição recebida do app. */
    public PosicaoResponseDTO salvarPosicao(PosicaoRequestDTO dto) {
        PosicaoVeiculo entidade = PosicaoVeiculo.builder()
                .placaVeiculo(dto.placaVeiculo())
                .latitude(dto.latitude())
                .longitude(dto.longitude())
                .velocidade(dto.velocidade())
                .build();

        PosicaoVeiculo salvo = repository.save(entidade);
        return toResponse(salvo);
    }

    /** Retorna a última posição conhecida de um veículo. */
    public Optional<PosicaoResponseDTO> buscarUltimaPosicao(String placa) {
        return repository
                .findUltimaPosicaoByPlaca(placa)
                .map(this::toResponse);
    }

    private PosicaoResponseDTO toResponse(PosicaoVeiculo p) {
        return new PosicaoResponseDTO(
                p.getId(),
                p.getPlacaVeiculo(),
                p.getLatitude(),
                p.getLongitude(),
                p.getVelocidade(),
                p.getTimestamp()
        );
    }
}
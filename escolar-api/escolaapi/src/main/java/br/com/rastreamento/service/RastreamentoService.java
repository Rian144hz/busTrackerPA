package br.com.rastreamento.service;

import br.com.rastreamento.dto.PosicaoRequestDTO;
import br.com.rastreamento.dto.PosicaoResponseDTO;
import br.com.rastreamento.exceptions.infra.FirebaseIndisponivelException;
import br.com.rastreamento.exceptions.rastreamento.CoordenadasForaDoBrasilException;
import br.com.rastreamento.exceptions.rastreamento.PosicaoInvalidaException;
import br.com.rastreamento.model.PosicaoVeiculo;
import br.com.rastreamento.repository.PosicaoVeiculoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RastreamentoService {

    private final PosicaoVeiculoRepository repository;
    private final FirebaseService firebaseService;

    public PosicaoResponseDTO salvarPosicao(PosicaoRequestDTO dto) {


        validarCoordenadas(dto.latitude(), dto.longitude());


        PosicaoVeiculo entidade = PosicaoVeiculo.builder()
                .cpf(dto.cpf())
                .nome(dto.nome())
                .placaVeiculo(dto.placaVeiculo())
                .latitude(dto.latitude())
                .longitude(dto.longitude())
                .velocidade(dto.velocidade())
                .motivoAtraso(dto.motivoAtraso())
                .build();


        PosicaoVeiculo salvo = repository.save(entidade);


        if (dto.motivoAtraso() != null && !dto.motivoAtraso().isBlank()) {
            try {
                firebaseService.enviarNotificacaoAtraso(dto.placaVeiculo(), dto.motivoAtraso());
            } catch (Exception e) {
                throw new FirebaseIndisponivelException(e.getMessage());
            }
        }

        return toResponse(salvo);
    }

    public Optional<PosicaoResponseDTO> buscarUltimaPosicao(String placa) {
        return repository.findUltimaPosicaoByPlaca(placa).map(this::toResponse);
    }

    public List<PosicaoResponseDTO> listarAtrasos() {
        return repository.findByMotivoAtrasoIsNotNullOrderByTimestampDesc()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }


    private void validarCoordenadas(BigDecimal lat, BigDecimal lon) {
        if (lat == null || lon == null) {
            throw new PosicaoInvalidaException("latitude e longitude são obrigatórias");
        }

        boolean foraDoBrasil = lat.doubleValue() < -33.8
                || lat.doubleValue() >   5.3
                || lon.doubleValue() < -73.9
                || lon.doubleValue() >  -28.6;

        if (foraDoBrasil) {
            throw new CoordenadasForaDoBrasilException(
                    lat.doubleValue(),
                    lon.doubleValue()
            );
        }
    }

    private PosicaoResponseDTO toResponse(PosicaoVeiculo p) {
        return new PosicaoResponseDTO(
                p.getId(),
                p.getCpf().toString(),  // Long → String
                p.getNome(),
                p.getPlacaVeiculo(),
                p.getLatitude(),
                p.getLongitude(),
                p.getVelocidade(),
                p.getTimestamp()
        );

    }
}
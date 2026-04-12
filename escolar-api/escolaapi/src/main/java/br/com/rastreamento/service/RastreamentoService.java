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

/**
 * Service responsavel pela logica de rastreamento.
 * Processa e persiste posicoes GPS, gerencia notificacoes.
 */
@Service
@RequiredArgsConstructor
public class RastreamentoService {

    private final PosicaoVeiculoRepository repository;
    private final FirebaseService firebaseService;

    /**
     * Persiste uma nova posicao GPS e dispara notificacao se houver atraso.
     *
     * @param dto dados da posicao recebidos do app
     * @return DTO com a posicao salva
     */
    public PosicaoResponseDTO salvarPosicao(PosicaoRequestDTO dto) {
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
            firebaseService.enviarNotificacaoAtraso(dto.placaVeiculo(), dto.motivoAtraso());
        }

        return toResponse(salvo);
    }

    /**
     * Busca a ultima posicao registrada de um veiculo.
     *
     * @param placa placa do veiculo
     * @return Optional com a posicao mais recente
     */
    public Optional<PosicaoResponseDTO> buscarUltimaPosicao(String placa) {
        return repository.findUltimaPosicaoByPlaca(placa).map(this::toResponse);
    }

    /**
     * Lista todos os registros com motivo de atraso preenchido.
     *
     * @return lista de posicoes ordenadas da mais recente para a mais antiga
     */
    public List<PosicaoResponseDTO> listarAtrasos() {
        return repository.findByMotivoAtrasoIsNotNullOrderByTimestampDesc()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Converte entidade PosicaoVeiculo para DTO de resposta.
     * Converte CPF de Long para String.
     *
     * @param p entidade a ser convertida
     * @return DTO equivalente
     */
    private PosicaoResponseDTO toResponse(PosicaoVeiculo p) {
        return new PosicaoResponseDTO(
                p.getId(),
                String.valueOf(p.getCpf()),
                p.getNome(),
                p.getPlacaVeiculo(),
                p.getLatitude(),
                p.getLongitude(),
                p.getVelocidade(),
                p.getTimestamp()
        );
    }
}

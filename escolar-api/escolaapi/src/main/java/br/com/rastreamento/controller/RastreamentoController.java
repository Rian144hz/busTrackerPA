package br.com.rastreamento.controller;

import br.com.rastreamento.dto.PosicaoRequestDTO;
import br.com.rastreamento.dto.PosicaoResponseDTO;
import br.com.rastreamento.service.RastreamentoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;


/**
 * Controller responsavel pelos endpoints de rastreamento de veiculos.
 * Gerencia o envio e consulta de posicoes GPS.
 */
@RestController
@RequestMapping("/api/v1/rastreamento")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class RastreamentoController {

    private final RastreamentoService service;

    /**
     * Recebe e persiste uma nova posicao GPS do veiculo.
     * POST /api/v1/rastreamento/enviar
     *
     * @param dto dados da posicao enviados pelo app do motorista
     * @return ResponseEntity com a posicao salva e status 201 (CREATED)
     */
    @PostMapping("/enviar")
    public ResponseEntity<PosicaoResponseDTO> enviarPosicao(
            @RequestBody PosicaoRequestDTO dto) {

        PosicaoResponseDTO resposta = service.salvarPosicao(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(resposta);
    }

    /**
     * Retorna a ultima posicao conhecida de um veiculo especifico.
     * GET /api/v1/rastreamento/veiculo/{placa}/ultima-posicao
     *
     * @param placa placa do veiculo (path variable)
     * @return ResponseEntity com a posicao (200) ou nao encontrado (404)
     */
    @GetMapping("/veiculo/{placa}/ultima-posicao")
    public ResponseEntity<PosicaoResponseDTO> ultimaPosicao(@PathVariable String placa) {
        var busca = service.buscarUltimaPosicao(placa);

        if (busca.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(busca.get());
    }

    /**
     * Lista todos os registros que possuem motivo de atraso.
     * GET /api/v1/rastreamento/atrasos
     *
     * @return ResponseEntity com lista de atrasos ordenados do mais recente
     */
    @GetMapping("/atrasos")
    public ResponseEntity<List<PosicaoResponseDTO>> listarAtrasos() {
        List<PosicaoResponseDTO> atrasos = service.listarAtrasos();
        return ResponseEntity.ok(atrasos);
    }

}

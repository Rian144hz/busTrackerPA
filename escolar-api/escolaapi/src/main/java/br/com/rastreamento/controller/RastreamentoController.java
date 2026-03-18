package br.com.rastreamento.controller;

import br.com.rastreamento.dto.PosicaoRequestDTO;
import br.com.rastreamento.dto.PosicaoResponseDTO;
import br.com.rastreamento.service.RastreamentoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/v1/rastreamento")
@RequiredArgsConstructor
public class RastreamentoController {

    private final RastreamentoService service;

    /**
     * POST /api/v1/rastreamento/enviar
     *
     * Recebe a localização atual do motorista (app Flutter).
     *
     * Exemplo de body:
     * {
     *   "placaVeiculo": "ABC-1234",
     *   "latitude": -9.4062,
     *   "longitude": -38.2144,
     *   "velocidade": 45.5
     * }
     */
    @PostMapping("/enviar")
    public ResponseEntity<PosicaoResponseDTO> enviarPosicao(
            @RequestBody PosicaoRequestDTO dto) {

        PosicaoResponseDTO resposta = service.salvarPosicao(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(resposta);
    }

    /**
     * GET /api/v1/rastreamento/veiculo/{placa}/ultima-posicao
     *
     * Retorna a posição mais recente do veículo informado.
     * Exemplo: GET /api/v1/rastreamento/veiculo/ABC-1234/ultima-posicao
     */
    @GetMapping("/veiculo/{placa}/ultima-posicao")
    public ResponseEntity<PosicaoResponseDTO> ultimaPosicao(@PathVariable String placa) {
        var busca = service.buscarUltimaPosicao(placa);

        if (busca.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(busca.get());
    }
}
package br.com.rastreamento.controller;

import br.com.rastreamento.dto.PosicaoRequestDTO;
import br.com.rastreamento.dto.PosicaoResponseDTO;
import br.com.rastreamento.service.RastreamentoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@RequestMapping("/api/v1/rastreamento")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class RastreamentoController {

    private final RastreamentoService service;

    @PostMapping("/enviar")
    public ResponseEntity<PosicaoResponseDTO> enviarPosicao(
            @RequestBody PosicaoRequestDTO dto) {

        PosicaoResponseDTO resposta = service.salvarPosicao(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(resposta);
    }


    @GetMapping("/veiculo/{placa}/ultima-posicao")
    public ResponseEntity<PosicaoResponseDTO> ultimaPosicao(@PathVariable String placa) {
        var busca = service.buscarUltimaPosicao(placa);

        if (busca.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(busca.get());
    }
    @GetMapping("/atrasos")
    public ResponseEntity<List<PosicaoResponseDTO>> listarAtrasos() {
        List<PosicaoResponseDTO> atrasos = service.listarAtrasos();
        return ResponseEntity.ok(atrasos);
    }

}
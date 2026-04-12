package br.com.rastreamento.controller;

import br.com.rastreamento.dto.LoginMotoristaRequestDTO;
import br.com.rastreamento.dto.LoginMotoristaResponseDTO;
import br.com.rastreamento.dto.LoginPaiRequestDTO;
import br.com.rastreamento.dto.LoginPaiResponseDTO;
import br.com.rastreamento.service.LoginService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller responsavel pelos endpoints de autenticacao.
 * Expoe operacoes de login para pais e motoristas.
 */
@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class LoginController {

    private final LoginService loginService;

    /**
     * Realiza login do responsavel.
     * POST /api/v1/auth/pai
     *
     * @param dto dados de login (matricula e nome do responsavel)
     * @return ResponseEntity com dados do aluno (200) ou nao autorizado (401)
     */
    @PostMapping("/pai")
    public ResponseEntity<LoginPaiResponseDTO> loginPai(
            @RequestBody LoginPaiRequestDTO dto) {

        return loginService.loginPai(dto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.status(401).build());
    }

    /**
     * Realiza login do motorista.
     * POST /api/v1/auth/motorista
     *
     * @param dto dados de login (cpf, nome e placa)
     * @return ResponseEntity com dados do motorista (200) ou nao autorizado (401)
     */
    @PostMapping("/motorista")
    public ResponseEntity<LoginMotoristaResponseDTO> loginMotorista(
            @RequestBody LoginMotoristaRequestDTO dto) {

        return loginService.loginMotorista(dto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.status(401).build());
    }
}

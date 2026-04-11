package br.com.rastreamento.controller;

import br.com.rastreamento.dto.LoginMotoristaRequestDTO;
import br.com.rastreamento.dto.LoginMotoristaResponseDTO;
import br.com.rastreamento.dto.LoginPaiRequestDTO;
import br.com.rastreamento.dto.LoginPaiResponseDTO;
import br.com.rastreamento.service.LoginService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class LoginController {

    private final LoginService loginService;

    @PostMapping("/pai")
    public ResponseEntity<LoginPaiResponseDTO> loginPai(
            @RequestBody LoginPaiRequestDTO dto) {

        return loginService.loginPai(dto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.status(401).build());
    }



    @PostMapping("/motorista")
    public ResponseEntity<LoginMotoristaResponseDTO> loginMotorista(
            @RequestBody LoginMotoristaRequestDTO dto) {

        return loginService.loginMotorista(dto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.status(401).build());
    }
}
# BusTracker PA

Sistema de rastreamento veicular em tempo real para o transporte escolar público de Paulo Afonso — BA.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=flat-square&logo=spring-boot&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat-square&logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)
![Status](https://img.shields.io/badge/status-MVP_validado-success?style=flat-square)

---

## O problema

No sertão baiano, famílias que dependem do transporte escolar público não têm como saber onde o ônibus está, se está atrasado ou quando vai chegar. Pais esperam horas em pontos de parada. Alunos ficam expostos ao sol e à chuva sem nenhuma previsão. Atrasos acontecem sem comunicação.

O BusTracker PA resolve isso com rastreamento GPS em tempo real, notificações push de atraso e visualização do trajeto no mapa — direto no celular dos responsáveis.

---

## Como funciona

O motorista abre o app, inicia o rastreamento e o sistema envia a posição GPS para o backend a cada 10 segundos. Se houver atraso, ele seleciona o motivo — o sistema dispara uma notificação push para todos os responsáveis via Firebase Cloud Messaging. O app dos pais atualiza o mapa automaticamente com a posição e o rastro do trajeto.

```
App Motorista (Flutter)
    └── POST /api/v1/rastreamento/enviar  →  Spring Boot API
                                                  ├── PostgreSQL (persiste telemetria)
                                                  └── Firebase FCM (push de atraso)
                                                          └── App Responsável (Flutter)
                                                                  └── GET /veiculo/{placa}/ultima-posicao
```

---

## Stack

**Backend**
- Java 21 + Spring Boot 3.x
- Spring Data JPA + PostgreSQL
- Firebase Admin SDK (FCM)
- Lombok

**Mobile**
- Flutter (Dart)
- `geolocator` — captura GPS real do dispositivo
- `flutter_map` + OpenStreetMap — renderização do mapa
- `firebase_messaging` — recebimento de push notifications

**Infraestrutura (MVP)**
- Linux Ubuntu (servidor local)
- Ngrok (túnel reverso para exposição WAN durante testes)
- DBeaver (administração do PostgreSQL)

---

## Estrutura do projeto

```
bustrackerpa/
├── escolar-api/                        # Backend Spring Boot
│   └── src/main/java/br/com/rastreamento/
│       ├── config/                     # CORS, Firebase
│       ├── controller/                 # Endpoints REST
│       ├── dto/                        # Request e Response DTOs
│       ├── exceptions/                 # Hierarquia de exceções por domínio
│       │   ├── auth/
│       │   ├── rastreamento/
│       │   ├── validacao/
│       │   └── infra/
│       ├── model/                      # Entidades JPA
│       ├── repository/                 # Interfaces Spring Data
│       └── service/                    # Regras de negócio
│
└── escolar_app/                        # App Flutter
    └── lib/
        ├── screen/                     # Telas por perfil
        └── service/                    # ApiService, AuthService, LocationService
```

---

## Endpoints da API

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/api/v1/auth/motorista` | Autenticação do motorista (CPF + nome + placa) |
| `POST` | `/api/v1/auth/pai` | Autenticação do responsável (matrícula + nome) |
| `POST` | `/api/v1/rastreamento/enviar` | Recebe posição GPS do motorista |
| `GET`  | `/api/v1/rastreamento/veiculo/{placa}/ultima-posicao` | Retorna última posição do veículo |
| `GET`  | `/api/v1/rastreamento/atrasos` | Lista registros com motivo de atraso |

---

## Rodando localmente

**Backend**

```bash
cd escolar-api/escolaapi
# Configure application.properties com suas credenciais do PostgreSQL
# Adicione serviceAccountKey.json em src/main/resources/
./mvnw spring-boot:run
```

**App Flutter**

```bash
cd escolar_app
flutter pub get
# Configure a baseUrl em lib/service/api_service.dart e auth_service.dart
flutter run
```

---

## Validação em campo

O sistema foi testado em rota real entre o **Distrito de Quixaba** e o **Povoado Torquato (Glória-BA)** — zona rural com cobertura de rede móvel intermitente. O motorista transmitiu posição via rede externa (Ngrok) e o responsável recebeu a atualização com latência inferior a 2 segundos.

---

## Roadmap

- [ ] Algoritmo de ETA (previsão de chegada por velocidade + distância)
- [ ] Geofencing — alerta ao entrar no raio da residência do aluno
- [ ] Painel web para gestores escolares
- [ ] Autenticação JWT
- [ ] Deploy em VPS com domínio fixo e SSL
- [ ] Arquitetura multi-tenant (múltiplas escolas)

---

## Sobre o projeto

Desenvolvido como projeto autoral durante o curso de Análise e Desenvolvimento de Sistemas no **IFBA — Campus Paulo Afonso**. A arquitetura, modelagem de dados e regras de negócio foram definidas pelo autor. Ferramentas de IA foram utilizadas como apoio no desenvolvimento de interfaces e debug de ambiente Linux.

**Paulo Afonso — BA, 2025**

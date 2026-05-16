# BusTracker PA

> Plataforma Full Stack de rastreamento veicular em tempo real para o transporte escolar público de Paulo Afonso — BA.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Java-21-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-MVP_Validado-success?style=for-the-badge" />
</p>

---

## Problema

No sertão baiano, famílias que dependem do transporte escolar público convivem diariamente com a incerteza sobre a localização dos ônibus. A ausência de informação gera esperas prolongadas sob sol e chuva, atrasos imprevistos sem comunicação e ansiedade entre pais e responsáveis.

O BusTracker PA resolve esse problema com uma solução tecnológica acessível, de baixo custo operacional e projetada para funcionar em condições de conectividade instável — realidade da região de Paulo Afonso.

---

## Demonstração

### Seleção de Perfil e Cadastro

| Seleção de Perfil | Cadastro Motorista | Cadastro Responsável |
|:---:|:---:|:---:|
| <img src="screenshotsapp/tela_inicial_app.jpeg" width="220"> | <img src="screenshotsapp/motorista_cpf.jpeg" width="220"> | <img src="screenshotsapp/cadastro_pai.jpeg" width="220"> |

### Painel do Motorista — Durante a Rota

| Aguardando Início | Transmitindo Localização | Atraso Ativo | Motivos Disponíveis |
|:---:|:---:|:---:|:---:|
| <img src="screenshotsapp/tela_motorista.jpeg" width="170"> | <img src="screenshotsapp/tela_enviando_localizacao.jpeg" width="170"> | <img src="screenshotsapp/tela_atraso.jpeg" width="170"> | <img src="screenshotsapp/opcoes_atrasos.jpeg" width="170"> |

### Painel dos Responsáveis — Monitoramento em Tempo Real

| Acompanhamento ao Vivo | Falha de Conexão |
|:---:|:---:|
| <img src="screenshotsapp/tela_pai.jpeg" width="260"> | <img src="screenshotsapp/tela_localizacao_falhou.jpeg" width="260"> |

---

## Validação em Campo

O MVP foi testado em uma rota real entre o **Distrito de Quixaba** e o **Povoado Torquato (Glória-BA)** — percurso rural com cobertura de rede móvel intermitente.

<p align="center">
  <kbd><img src="screenshotsapp/tela_quixaba.jpeg" width="255px"></kbd>
  &nbsp;&nbsp;&nbsp;
  <kbd><img src="screenshotsapp/tela_torquato.jpeg" width="255px"></kbd>
</p>
<p align="center"><em>Motorista na Quixaba (esq.) · Responsável no Torquato (dir.)</em></p>

<p align="center">
  <img src="screenshotsapp/tela_ngrokemoji.jpeg" width="580px">
</p>
<p align="center"><em>Logs do servidor (Ngrok) registrando requisições POST originadas via rede móvel</em></p>

**Resultado:** transmissão de dados por rede externa com latência média inferior a **2 segundos** — comprovado em condições reais de campo.

---

## Arquitetura

O sistema opera em três camadas desacopladas, com comunicação via HTTP REST e notificações push assíncronas via Firebase Cloud Messaging.

```
┌──────────────────────────────────────────────┐
│                 CAMADA CLIENTE               │
│                                              │
│   App Motorista (Flutter)                    │
│   POST /api/v1/rastreamento/enviar           │
│                                              │
│   App Responsável (Flutter)                  │
│   GET /veiculo/{placa}/ultima-posicao        │
└──────────────────────┬───────────────────────┘
                       │
┌──────────────────────▼───────────────────────┐
│             CAMADA DE APLICAÇÃO              │
│          Spring Boot 3 · Java 21             │
│                                              │
│  RastreamentoController                      │
│  RastreamentoService                         │
│  FirebaseService (FCM)                       │
│  Spring Data JPA · PostgreSQL                │
└──────────────────────┬───────────────────────┘
                       │ Push Notification
┌──────────────────────▼───────────────────────┐
│           FIREBASE CLOUD MESSAGING           │
│   Tópico: onibus_paulo_afonso                │
│   Latência média: < 2 segundos               │
└──────────────────────────────────────────────┘
```

---

## Fluxo de Notificações

**1. App do Motorista** — O `LocationService` captura coordenadas via `geolocator` e o `ApiService` envia o payload ao backend:

```json
POST /api/v1/rastreamento/enviar
{
  "cpf": 12345678900,
  "placaVeiculo": "ABC-1234",
  "latitude": -9.4062,
  "longitude": -38.2144,
  "velocidade": 45.5,
  "motivoAtraso": "Pneu furado"
}
```

**2. API REST** — O `RastreamentoService` persiste a telemetria no PostgreSQL e, se houver atraso, aciona o `FirebaseService`:

```java
@Transactional
public void processarPosicao(PosicaoRequestDTO dto) {
    posicaoRepository.save(dto.toEntity());

    if (StringUtils.hasText(dto.motivoAtraso())) {
        firebaseService.enviarNotificacaoAtraso(dto.placaVeiculo(), dto.motivoAtraso());
    }
}
```

**3. Firebase Cloud Messaging** — Publica no tópico `onibus_paulo_afonso`, atingindo todos os dispositivos inscritos sem necessidade de tokens individuais:

```java
public String enviarNotificacaoAtraso(String placa, String motivo) {
    Message message = Message.builder()
        .setTopic("onibus_paulo_afonso")
        .setNotification(Notification.builder()
            .setTitle("⚠️ Atraso no ônibus " + placa)
            .setBody("Motivo: " + motivo)
            .build())
        .build();

    return FirebaseMessaging.getInstance().send(message);
}
```

**4. App dos Responsáveis** — Recebe a notificação via `FirebaseMessaging.onMessage`, exibindo um banner nativo mesmo com o app em segundo plano.

---

## Stack Tecnológica

### Mobile — Flutter

| Responsabilidade | Pacote |
|---|---|
| Captura de GPS | `geolocator` |
| Renderização de mapas (OpenStreetMap) | `flutter_map` + `latlong2` |
| Comunicação HTTP | `http` (Dart SDK) |
| Notificações Push | `firebase_messaging` |
| Internacionalização | `intl` |

### Backend — Spring Boot

| Responsabilidade | Tecnologia |
|---|---|
| Linguagem e runtime | Java 21 (LTS) |
| Framework | Spring Boot 3.x |
| Persistência | Spring Data JPA + PostgreSQL 14 |
| Redução de boilerplate | Lombok |
| Push Notifications | Firebase Admin SDK |
| Build | Maven |

Padrões adotados: MVC, Repository Pattern, DTOs imutáveis, Injeção de Dependências via IoC Spring.

### Infraestrutura

| Responsabilidade | Tecnologia |
|---|---|
| Banco de dados | PostgreSQL 14+ |
| Sistema operacional | Linux Ubuntu |
| Mensageria | Firebase Cloud Messaging |
| Túnel reverso (MVP) | Ngrok |

---

## Persistência de Dados

| Telemetria (Posições) | Controle de Acesso (Alunos) |
|:---:|:---:|
| <img src="screenshotsapp/Captura de tela de 2026-03-20 11-40-28.png" width="380"> | <img src="screenshotsapp/Captura de tela de 2026-03-20 12-54-40.png" width="380"> |
| Tabela `atrasos` com dados completos de telemetria | Tabela `alunos` com vínculo familiar e status |

---

## Estrutura do Repositório

```
bustrackerpa/
├── escolar-api/                        # Backend Spring Boot
│   └── escolaapi/src/main/java/br/com/rastreamento/
│       ├── config/                     # CORS, Firebase, Security
│       ├── controller/                 # Endpoints REST
│       ├── dto/                        # Data Transfer Objects
│       ├── model/                      # Entidades JPA
│       ├── repository/                 # Interfaces Spring Data JPA
│       └── service/                    # Regras de negócio + Firebase
│
└── escolar_app/                        # Frontend Flutter
    ├── android/
    └── lib/
        ├── screen/                     # Telas (Seleção, Motorista, Responsável)
        └── service/                    # ApiService, AuthService, LocationService
```

---

## Instalação e Configuração

### Pré-requisitos

- JDK 21+, Maven 3.9+
- Flutter SDK 3.x (stable)
- PostgreSQL 14+
- Conta Firebase (plano gratuito)

### Backend

```bash
git clone https://github.com/rian144hz/bustrackerpa.git
cd bustrackerpa/escolar-api/escolaapi
```

Configure `src/main/resources/application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/bustrackerpa
spring.datasource.username=SEU_USUARIO
spring.datasource.password=SUA_SENHA
spring.jpa.hibernate.ddl-auto=update
```

Adicione `serviceAccountKey.json` (gerado no Firebase Console) em `src/main/resources/` e execute:

```bash
./mvnw spring-boot:run
```

A API ficará disponível em `http://localhost:8080`.

### Frontend

```bash
cd bustrackerpa/escolar_app
flutter pub get
```

Defina a URL base em `lib/service/api_service.dart`:

```dart
static const String baseUrl = 'http://SEU_IP_LOCAL:8080/api/v1/rastreamento';
```

Adicione o arquivo `google-services.json` (baixado do Firebase Console) em `android/app/` e execute:

```bash
flutter run
```

---

## Roadmap

- [ ] ETA (Estimated Time of Arrival) baseado em velocidade média e histórico de rotas
- [ ] Geofencing — alertas automáticos por proximidade da residência
- [ ] Autenticação JWT com tokens expiráveis e revogáveis
- [ ] Painel administrativo web (React) para gestores monitorarem múltiplas rotas
- [ ] Deploy em VPS (Railway / AWS Lightsail) com domínio fixo e SSL
- [ ] Arquitetura multi-tenant para suporte a múltiplas escolas e municípios
- [ ] Publicação na App Store (iOS)

---

## Sobre o Projeto

O BusTracker PA nasceu da observação direta das dificuldades de mobilidade escolar no interior da Bahia. A arquitetura, modelagem de dados, endpoints REST e integração com Firebase foram concebidos e implementados pelo desenvolvedor. A IA foi utilizada como ferramenta de aceleração em partes da implementação Flutter, refinamento de código e debug de ambiente Linux.

Todas as decisões críticas de segurança, regras de negócio e validação em campo foram conduzidas com supervisão humana direta.

---

<p align="center">Desenvolvido com ☕ e Flutter no sertão da Bahia · <strong>Paulo Afonso — BA · 2025</strong></p>

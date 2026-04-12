# 🚌 BusTracker PA — Plataforma de Mobilidade Escolar

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Linux_Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-MVP_Validado-success?style=for-the-badge" />
</p>

<p align="center">
  <strong>Uma solução Full Stack de rastreamento veicular em tempo real para o transporte escolar público de Paulo Afonso — BA.</strong><br/>
  Desenvolvida para conectar motoristas, responsáveis e gestores escolares em uma única plataforma segura, confiável e escalável.
</p>

---

## 🎯 O Problema que Resolvemos

No sertão baiano, famílias que dependem do transporte escolar público enfrentam uma realidade frustrante: **incerteza**. Sem informação sobre a localização ou o horário do ônibus, pais chegam cedo demais às paradas, alunos ficam esperando sob o sol, e atrasos viram surpresas. O BusTracker PA elimina essa incerteza com tecnologia acessível e de baixo custo operacional.

---

## 🏗️ Arquitetura da Solução

O sistema opera sobre três camadas integradas:

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENTE (Mobile)                        │
│  App Motorista (Flutter) ──────► App Responsável (Flutter)  │
└────────────┬───────────────────────────────┬────────────────┘
             │ POST /enviar (REST)            │ GET /ultima-posicao
             ▼                               │
┌─────────────────────────┐                 │
│   API REST (Spring Boot) │ ────────────────┘
│   Java 21 + PostgreSQL   │
│   + Firebase SDK (FCM)   │
└────────────┬────────────┘
             │ Push Notification
             ▼
┌─────────────────────────┐
│  Firebase Cloud Messaging│
│  Tópico: onibus_paulo_   │
│          afonso          │
└─────────────────────────┘
```

---

## 🔔 Fluxo de Notificações: Da Origem ao Destino

Este é o fluxo técnico completo que garante que pais sejam alertados em tempo real sobre atrasos:

### 1. 📱 Origem — App do Motorista (Flutter)
O motorista abre o app, informa o motivo do atraso (ex: "Pneu furado") e continua o rastreamento. O `LocationService` captura as coordenadas GPS via `geolocator` e o `ApiService` empacota os dados em um payload JSON e dispara um `POST` para a API:

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

### 2. ⚙️ Processamento — API REST em Spring Boot
O `RastreamentoController` recebe a requisição e a delega ao `RastreamentoService`. O service executa duas operações atômicas:
- **Persistência:** Salva o registro de telemetria na tabela `atrasos` do PostgreSQL via JPA.
- **Triagem:** Verifica se `motivoAtraso` está presente. Se sim, delega para o `FirebaseService`.

```java
// RastreamentoService.java
if (dto.motivoAtraso() != null && !dto.motivoAtraso().isBlank()) {
    firebaseService.enviarNotificacaoAtraso(dto.placaVeiculo(), dto.motivoAtraso());
}
```

### 3. 🔥 Mensageria — Firebase Cloud Messaging (FCM)
O `FirebaseService` constrói uma `Notification` com título e corpo dinâmicos e publica a mensagem no tópico `onibus_paulo_afonso`. Todos os dispositivos inscritos nesse tópico recebem o push instantaneamente, sem necessidade de conhecer o token individual de cada aparelho.

```java
// FirebaseService.java
Message message = Message.builder()
    .setTopic("onibus_paulo_afonso")
    .setNotification(notification)
    .build();
FirebaseMessaging.getInstance().send(message);
```

### 4. 🏠 Destino — Notificação no App do Responsável (Flutter)
O app dos pais, inscrito no mesmo tópico no momento do login, recebe o push via `FirebaseMessaging.onMessage`. O alerta aparece como banner nativo no Android, mesmo com o app em background, graças ao handler configurado em `main.dart`.

```
Latência média end-to-end (validada em campo): < 2 segundos
```

---

## 📸 Demonstração das Interfaces

### 🏠 Fluxo de Acesso e Perfis
| Seleção de Perfil | Cadastro Motorista | Cadastro Responsável |
|:---:|:---:|:---:|
| <img src="screenshotsapp/tela_inicial_app.jpeg" width="230"> | <img src="screenshotsapp/motorista_cpf.jpeg" width="230"> | <img src="screenshotsapp/cadastro_pai.jpeg" width="230"> |
| *Escolha de papel* | *Identificação e Placa* | *Vínculo via Matrícula* |

### 🚛 Painel do Motorista (Em Rota)
| Aguardando Início | Localização Enviada | Alerta de Atraso Ativo | Motivos Disponíveis |
|:---:|:---:|:---:|:---:|
| <img src="screenshotsapp/tela_motorista.jpeg" width="180"> | <img src="screenshotsapp/tela_enviando_localizacao.jpeg" width="180"> | <img src="screenshotsapp/tela_atraso.jpeg" width="180"> | <img src="screenshotsapp/opcoes_atrasos.jpeg" width="180"> |
| *Mapa Base* | *Feedback de Envio* | *Banner de Alerta* | *Lista Pré-definida* |

### 👨‍👩‍👦 Painel dos Pais (Monitoramento)
| Acompanhamento ao Vivo | Tratamento de Erro |
|:---:|:---:|
| <img src="screenshotsapp/tela_pai.jpeg" width="250"> | <img src="screenshotsapp/tela_localizacao_falhou.jpeg" width="250"> |
| *Ônibus em Movimento* | *Feedback de Conexão* |

---

## 🧪 Validação em Campo: "O Teste da Quixaba"

O maior marco do projeto foi o teste real de longa distância conectando o **Distrito de Quixaba** ao **Povoado Torquato (Glória-BA)** — dois pontos separados por zona rural, com cobertura de rede móvel limitada.

### 📱 Dois Dispositivos, Uma Conexão em Tempo Real
<p align="center">
  <kbd>
    <img src="screenshotsapp/tela_quixaba.jpeg" alt="Motorista na Quixaba" width="260px">
  </kbd>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <kbd>
    <img src="screenshotsapp/tela_torquato.jpeg" alt="Responsável no Torquato" width="260px">
  </kbd>
</p>

### 🖥️ Monitoramento do Servidor (Logs do Ngrok)
Evidência técnica do túnel HTTP recebendo requisições `POST` vindas da Quixaba via rede móvel:

<p align="center">
  <img src="screenshotsapp/tela_ngrokemoji.jpeg" alt="Logs do Servidor Ngrok" width="600px" style="border-radius: 10px; border: 1px solid #ddd;">
</p>

> **Resultado:** O motorista (esquerda) enviou dados de uma rede externa e o responsável (direita) recebeu a posição com **latência inferior a 2 segundos**. Prova de conceito de que a arquitetura funciona em condições reais de campo.

---

## 🗄️ Backend e Persistência

| Registro de Telemetria (Posições) | Controle de Acesso (Responsáveis) |
|:---:|:---:|
| <img src="screenshotsapp/Captura de tela de 2026-03-20 11-40-28.png" width="400"> | <img src="screenshotsapp/Captura de tela de 2026-03-20 12-54-40.png" width="400"> |
| *Tabela `atrasos` com telemetria completa* | *Tabela `alunos` com controle de status ativo* |

---

## 🛠️ Stack Tecnológica

### 📱 Mobile — Flutter
| Responsabilidade | Tecnologia |
|---|---|
| GPS em tempo real | `geolocator` |
| Renderização de mapas | `flutter_map` (OpenStreetMap) + `latlong2` |
| Comunicação com API | `http` (REST assíncrono) |
| Notificações Push | `firebase_messaging` |

### ☕ Backend — Spring Boot
| Responsabilidade | Tecnologia |
|---|---|
| Linguagem e runtime | Java 21 / Spring Boot 3.x |
| Persistência | Spring Data JPA + PostgreSQL |
| Redução de boilerplate | Lombok |
| Push Notifications | Firebase Admin SDK (FCM) |

### ☁️ Infraestrutura e Cloud
| Responsabilidade | Tecnologia |
|---|---|
| Banco de dados relacional | PostgreSQL (gerenciado via DBeaver) |
| Servidor de aplicação | Linux Ubuntu |
| Túnel reverso para WAN | Ngrok (MVP) |
| Mensageria Push | Firebase Cloud Messaging (FCM) |

---

## 🚀 Guia de Instalação (Setup)

### Pré-requisitos
- Java 21+
- Maven 3.9+
- Flutter SDK 3.x
- PostgreSQL 14+
- Conta no Firebase (para FCM)

---

### ⚙️ Backend (Spring Boot)

**1. Clone o repositório e acesse a pasta do backend:**
```bash
git clone https://github.com/seu-usuario/bustrackerpa.git
cd bustrackerpa/escolar-api/escolaapi
```

**2. Configure o banco de dados** em `src/main/resources/application.properties`:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/postgres
spring.datasource.username=SEU_USUARIO
spring.datasource.password=SUA_SENHA
```

**3. Adicione as credenciais do Firebase:**
Baixe o arquivo `serviceAccountKey.json` do console do Firebase e coloque em:
```
src/main/resources/serviceAccountKey.json
```

**4. Execute a aplicação:**
```bash
./mvnw spring-boot:run
```
A API estará disponível em `http://localhost:8080`.

---

### 📱 Frontend (Flutter)

**1. Acesse a pasta do app e instale as dependências:**
```bash
cd bustrackerpa/
flutter pub get
```

**2. Configure a URL base da API** em `lib/service/api_service.dart` e `lib/service/auth_service.dart`:
```dart
static const String baseUrl = 'http://SEU_IP_OU_DOMINIO/api/v1/rastreamento';
```

**3. Adicione o arquivo `google-services.json`** (baixado do Firebase Console) em:
```
android/app/google-services.json
```

**4. Execute o app:**
```bash
flutter run
```

---

## 📈 Roadmap de Evolução

O MVP está validado. O caminho para o produto completo inclui:

- [ ] **🔔 Notificações Push Aprimoradas** — Personalização de alertas por rota e horário.
- [ ] **⏱️ Algoritmo de ETA** — Cálculo de previsão de chegada baseado em velocidade média e distância.
- [ ] **🚧 Geofencing** — Cercas virtuais para alertar quando o ônibus está a X metros da residência.
- [ ] **📊 Painel Administrativo** — Dashboard web para gestores escolares monitorarem todas as rotas.
- [ ] **🔐 Autenticação com JWT** — Substituir a validação simples por tokens assinados e expiráveis.
- [ ] **🌐 Deploy em Nuvem** — Migração do Ngrok para um servidor cloud (AWS/GCP/Railway) com domínio fixo e HTTPS.
- [ ] **🏫 Multi-tenancy** — Suporte a múltiplas escolas e municípios em uma única instância.

---

## 📂 Estrutura do Projeto

```
bustrackerpa/
├── 📦 escolar-api/                  # Backend Spring Boot (Java)
│   └── escolaapi/src/main/java/
│       ├── controller/              # Camada HTTP (REST endpoints)
│       ├── service/                 # Regras de negócio e Firebase
│       ├── repository/              # Acesso ao banco de dados (JPA)
│       ├── model/                   # Entidades JPA (Aluno, Motorista, PosicaoVeiculo)
│       ├── dto/                     # Objetos de transferência de dados (Request/Response)
│       └── config/                  # Configurações (CORS, Firebase)
│
└── 📦 rastreamento_escolar/         # App Mobile (Flutter)
    └── lib/
        ├── screen/                  # Interfaces (Seleção de Perfil, Motorista, Pai)
        └── service/                 # Lógica de negócio (API, GPS, Auth)
```

---

## 👨‍💻 Sobre o Desenvolvimento

Este projeto foi construído de forma autoral, com foco em resolução de um problema real da região de **Paulo Afonso-BA**.

- **Arquitetura:** Toda a modelagem do banco de dados, design dos endpoints REST e a lógica de integração com Firebase foram concebidos e implementados do zero.
- **Pair Programming com IA:** A IA foi utilizada como ferramenta de aceleração no desenvolvimento das interfaces Flutter e no debug do ambiente Linux, mantendo o foco humano nas decisões de arquitetura, segurança e regra de negócio.
- **Propósito:** Aplicar Engenharia de Software para trazer segurança e tranquilidade às famílias do sertão baiano.

---

<p align="center">
  Feito com ☕ e Flutter no sertão da Bahia.
</p>

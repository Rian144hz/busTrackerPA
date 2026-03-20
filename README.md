# 🚌 BusTracker - Sistema de Rastreamento Escolar (Paulo Afonso-BA)

O **BusTracker** é uma solução Full Stack real, idealizada e desenvolvida para monitorar o transporte escolar no Sertão da Bahia. O sistema permite que motoristas enviem sua localização em tempo real e que pais/responsáveis acompanhem o trajeto, velocidade e estimativa de chegada diretamente pelo celular.

## 🚀 Sobre o Desenvolvimento (Realidade do Projeto)

Este projeto é fruto de uma iniciativa **totalmente autoral**, unindo a necessidade real da região de **Paulo Afonso-BA** com as tecnologias que venho dominando no **IFBA**. 

A construção do **BusTracker PA** seguiu uma dinâmica de mercado moderna:

* **Arquitetura e Ideação:** Toda a estrutura do sistema, desde a modelagem do banco de dados em Java (Spring Boot) até a lógica de rastreamento, foi idealizada por mim.
* **Pair Programming com IA:** No processo de codificação, utilizei o **Claude (Anthropic)** como meu parceiro de programação. Ele foi essencial para agilizar a criação das interfaces no Flutter e auxiliar no debugging de ambiente no **Linux Ubuntu**, permitindo que eu focasse 100% na lógica de negócio e na integração do ecossistema.
* **Propósito:** Estou muito animado com o potencial desse projeto! Aplicar o que aprendi em Lógica de Programação e Java para resolver um problema do meu cotidiano é o que me motiva a evoluir como desenvolvedor.

---

### 📱 Sobre o Projeto
O aplicativo conecta a frota municipal aos cidadãos, trazendo segurança e previsibilidade para o transporte de alunos em Paulo Afonso — BA. O diferencial do projeto é a segmentação de perfis, garantindo que a informação certa chegue à pessoa certa.

#### ✅ Funcionalidades Atuais (MVP)

**Para o Motorista:**
* **Identificação:** Login personalizado com nome cpf e placa do veículo.
* **Telemetria:** Envio automático de localização GPS a cada 10 segundos para o servidor.
* **Gestão de Percurso:** Botões de controle para embarque/desembarque de alunos.
* **Comunicação de Incidentes:** Informe de atrasos com lista pré-definida (pneu furado, trânsito, etc) ou motivo personalizado.
* **Monitoramento:** Visualização da própria posição e velocidade no mapa.

**Para o Pai / Responsável:**
* **Autenticação de Responsáveis** Integração completa entre o aplicativo Flutter e o backend Spring Boot para validação de matrícula e nome do responsável.
* **Acesso Seguro:** Login utilizando a matrícula do aluno e nome do responsável.
* **Mapa ao Vivo:** Acompanhamento do ônibus em tempo real com rastro do percurso.
* **Painel de Informações:** Visualização da velocidade atual, status da conexão e última atualização.
* **Alertas:** Banner de notificação imediata caso o motorista informe algum atraso ou imprevisto.

---

## 📸 Demonstração do Aplicativo

O sistema conta com interfaces distintas e intuitivas para cada tipo de usuário.

### 🏠 Fluxo de Acesso
| Seleção de Perfil | Cadastro Motorista | Cadastro Pai / Responsável |
|:---:|:---:|:---:|
| <img src="screenshotsapp/tela_inicial_app.jpeg" width="250"> | <img src="screenshotsapp/motorista_cpf.jpeg" width="250"> | <img src="screenshotsapp/cadastro_pai.jpeg" width="250"> |
| Escolha entre os perfis | Identificação por Nome e Placa | Acesso via Matrícula e Nome |

### 🚛 Interface do Motorista (Em Rota)
| Aguardando Início | Localização Enviada | Alerta de Atraso | Opções de Atraso |
|:---:|:---:|:---:|:---:|
| <img src="screenshotsapp/tela_motorista.jpeg" width="200"> | <img src="screenshotsapp/tela_enviando_localizacao.jpeg" width="200"> | <img src="screenshotsapp/tela_atraso.jpeg" width="200"> | <img src="screenshotsapp/opcoes_atrasos.jpeg" width="200"> |
| Mapa de Paulo Afonso | Confirmação de envio ao Java | Status de atraso ativo | Motivos pré-definidos |

### 👨‍👩‍👦 Interface dos Pais (Acompanhamento)
| Monitoramento ao Vivo | Falha de Conexão (Tratamento de Erro) |
|:---:|:---:|
| <img src="screenshotsapp/tela_pai.jpeg" width="250"> | <img src="screenshotsapp/tela_localizacao_falhou.jpeg" width="250"> |
| Visualização do ônibus e velocidade | Feedback em tempo real sobre instabilidades |

---

### 🛠️ Tecnologias Utilizadas

#### **Backend (Java Spring Boot)**
* **Linguagem:** Java 21
* **Framework:** Spring Boot 3.5.12 (Spring Data JPA)
* **Banco de Dados:** PostgreSQL (Gerenciado via DBeaver)
* **Produtividade:** Lombok para redução de código boilerplate.
* **Infraestrutura:** Servidor rodando em **Linux Ubuntu** com túnel reverso via **Ngrok** para testes externos em rede móvel (4G).

#### **Mobile (Flutter)**
* **Localização:** `geolocator` para captura de coordenadas GPS reais.
* **Mapas:** `flutter_map` (OpenStreetMap) e `latlong2`.
* **Comunicação:** Pacote `http` para integração com API REST (JSON).
* **Internacionalização:** `intl` para formatação de datas e horas locais.

---

### 🗂️ Estrutura do Projeto

```text
📦 rastreamento_escolar/          # App Flutter
└── lib/
    ├── main.dart
    ├── screen/ (tela_selecao_perfil.dart, tela_motorista.dart, tela_pai.dart)
    └── service/ (api_service.dart, location_service.dart)

📦 escolar-api/                   # Backend Java
└── src/main/java/.../
    ├── controller/ (RastreamentoController.java, AuthController.java)
    ├── service/ (RastreamentoService.java)
    ├── model/ (PosicaoVeiculo.java)
    └── config/ (CorsConfig.java)

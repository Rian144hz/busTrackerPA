# 🚌 BusTracker PA — Sistema de Rastreamento Escolar (Paulo Afonso-BA)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Linux_Ubuntu-E9430F?style=for-the-badge&logo=ubuntu&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-MVP_Validado-success?style=for-the-badge" />
</p>

O **BusTracker PA** é uma solução Full Stack autoral desenvolvida para monitorar o transporte escolar no Sertão da Bahia. O sistema permite que motoristas enviem sua localização em tempo real e que pais/responsáveis acompanhem o trajeto, velocidade e alertas de atraso diretamente pelo smartphone.

---

## 🚀 Sobre o Desenvolvimento (Realidade do Projeto)

Este projeto nasceu da vontade de aplicar os conhecimentos do **IFBA** para resolver um problema real da região de **Paulo Afonso-BA**.

* **Arquitetura Autoral:** Toda a modelagem do banco de dados, lógica de backend em Java e integração mobile foi idealizada por mim.
* **Pair Programming com IA:** No processo de codificação, utilizei o **Claude (Anthropic)** como parceiro estratégico. Essa colaboração permitiu acelerar o desenvolvimento das interfaces em Flutter e o debug do ambiente no **Linux Ubuntu**, focando a energia na regra de negócio e segurança.
* **Propósito:** Aplicar Lógica de Programação e Engenharia de Software para trazer segurança aos alunos e tranquilidade aos pais do sertão baiano.

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

O maior marco do projeto foi o teste real de longa distância conectando o **Distrito de Quixaba** ao **Povoado Torquato (Glória-BA)**.

<p align="center">
  <kbd>
    <img src="screenshotsapp/tela_quixaba.jpeg" alt="Demonstração do BusTrackerPA" width="600px">
  </kbd>
</p>

<p align="center">
  <kbd>
    <img src="screenshotsapp/tela_torquato.jpeg" alt="Demonstração do BusTrackerPA" width="600px">
  </kbd>
</p>

> **Prova de Conceito:** A imagem acima mostra o motorista (esquerda) na Quixaba enviando dados via 4G, e o pai (direita) no Torquato recebendo a posição em tempo real. Integração via **Ngrok** com latência inferior a 2 segundos.

---

## 🗄️ Backend & Persistência (Java + PostgreSQL)

O backend gerencia o fluxo de coordenadas e a segurança de acesso dos responsáveis.

| Registro de Localização (Posições) | Gestão de Responsáveis (Status Ativo) |
|:---:|:---:|
| <img src="screenshotsapp/Captura de tela de 2026-03-20 11-40-28.png" width="400"> | <img src="screenshotsapp/Captura de tela de 2026-03-20 12-54-40.png" width="400"> |
| *Logs de Telemetria* | *Controle de Acesso de Alunos* |

---

## 🛠️ Stack Tecnológica

### **Mobile (Flutter)**
* **GPS:** `geolocator` para captura de coordenadas reais.
* **Mapas:** `flutter_map` (OpenStreetMap) + `latlong2`.
* **Networking:** Integração com API REST via pacotes assíncronos.

### **Backend (Spring Boot)**
* **Linguagem:** Java 21 / Spring Boot 3.x.
* **Database:** PostgreSQL (Gerenciado via DBeaver).
* **Infra:** Linux Ubuntu + Ngrok (Túnel reverso para WAN).

---

## 📈 Roadmap de Evolução

- [ ] **🔔 Notificações Push:** Alertas fora do aplicativo via Firebase.
- [ ] **⏱️ Algoritmo ETA:** Cálculo de previsão de chegada baseado em velocidade média.
- [ ] **🚧 Geofencing:** Cercas virtuais para avisos de proximidade da residência.

---

## 📂 Estrutura do Projeto

```bash
├── 📦 escolar-api           # Backend Spring Boot (Java)
│   ├── src/main/java        # Controllers, Models e Services
│   └── resources/           # Configurações PostgreSQL e Application Props
└── 📦 rastreamento_escolar   # App Mobile (Flutter)
    ├── lib/screen           # Interfaces de cada perfil
    └── lib/service          # Lógica de API e GPS

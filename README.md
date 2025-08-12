# 📱 Gestão de Escala Mobile

> Aplicativo multiplataforma para gestão de escalas de trabalho — desenvolvido com **Flutter** para rodar em **iOS, Android e Web** com uma única base de código.

![Tecnologia - Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white)
![Linguagem - Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Plataformas](https://img.shields.io/badge/Plataformas-iOS%20%7C%20Android%20%7C%20Web-F6821F?style=for-the-badge&logo=google-chrome&logoColor=white)
![Estado - Provider/BLoC](https://img.shields.io/badge/State%20Management-Provider%20%7C%20BLoC-42A5F5?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23FFCA28.svg?style=for-the-badge&logo=firebase&logoColor=black)

---

## 📌 Visão Geral

**Gestão de Escala** é uma aplicação multiplataforma desenvolvida em **Flutter** com o objetivo de facilitar o controle de escalas de trabalho para profissionais que atuam em regime de turnos — como segurança, saúde, manutenção e operações logísticas.

Totalmente responsiva, a aplicação roda perfeitamente em **dispositivos móveis (iOS e Android)** e também no **navegador (Web)**, oferecendo uma experiência consistente em todos os dispositivos. Com uma interface limpa e intuitiva, permite ao usuário visualizar suas escalas, registrar pontos e acompanhar seu histórico com facilidade.

Ideal para equipes autônomas ou pequenas empresas que buscam uma solução leve, eficiente e sem custos elevados.

---

## 🚀 Funcionalidades Principais

- ✅ **Visualização de escalas** – diárias, semanais e mensais
- ✅ **Registro de ponto digital** – check-in e check-out com data e hora
- ✅ **Histórico de turnos** – acompanhamento de presença e ausência
- ✅ **Perfil do usuário** – dados pessoais, cargo, foto e contato
- ✅ **Autenticação segura** – login com e-mail e senha
- ✅ **Sincronização em tempo real** – dados atualizados entre dispositivos
- ✅ **Multiplataforma** – funciona em iOS, Android e Web com o mesmo código
- ✅ **Interface responsiva** – adaptada a telas de todos os tamanhos

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Função |
|----------|------|
| **Flutter** | Framework para desenvolvimento multiplataforma (mobile + web) |
| **Dart** | Linguagem de programação moderna e performática |
| **Firebase Auth** | Autenticação de usuários com e-mail/senha |
| **Cloud Firestore** | Banco de dados em tempo real para armazenar escalas e registros |
| **Provider / BLoC** | Gerenciamento de estado da aplicação |
| **Shared Preferences** | Armazenamento local de configurações e sessão |
| **intl** | Formatação de datas, horas e textos com suporte a múltiplos idiomas |
| **Flutter Web** | Compilação para execução no navegador |

---

## 🗂️ Estrutura de Pastas
lib/
├── main.dart # Ponto de entrada da aplicação

├── models/ # Classes de dados (User, Escala, Ponto, etc.)

├── services/ # Camadas de acesso ao Firebase (auth, firestore)

├── providers/ # Gerenciamento de estado (Provider ou BLoC)

├── screens/ # Telas da aplicação (Login, Home, Perfil, etc.)

├── widgets/ # Componentes reutilizáveis (CardEscala, BotaoCustomizado)

├── utils/ # Funções auxiliares (formatação, validação)

├── theme/ # Temas de cores, tipografia e estilo global

└── routes/ # Definição de rotas e navegação


---

## 🌐 Backend e Infraestrutura

O projeto utiliza o **Firebase da Google** como backend como serviço (BaaS), garantindo:

- 🔐 Autenticação segura com email/senha
- ☁️ Armazenamento em tempo real com Cloud Firestore
- 📦 Escalabilidade automática
- 📲 Notificações push (pronto para extensão)
- 🌍 Disponibilidade global

Essa escolha permite um desenvolvimento ágil, sem necessidade de um servidor próprio, ideal para MVPs e aplicações de pequeno/médio porte.

---

## 🧪 Arquitetura e Boas Práticas

- **Código limpo e modular** – separação clara entre camadas (UI, lógica, dados)
- **Reutilização de componentes** – widgets personalizados e estilizados
- **Gerenciamento de estado eficiente** – uso de Provider ou BLoC para evitar rebuilds desnecessários
- **Suporte a múltiplas plataformas** – mesma base de código para mobile e web
- **Internacionalização (i18n)** – preparado para suporte a múltiplos idiomas
- **Manutenibilidade** – estrutura escalável e documentada

---

## 🎯 Objetivo do Projeto

Criar uma solução **acessível, intuitiva e multiplataforma** para gestão de escalas, eliminando o uso de planilhas, anotações manuais ou sistemas complexos. Voltado para quem precisa de simplicidade com eficiência.

---

## 🤝 Contribuição

Contribuições são **bem-vindas**! Este projeto é uma ótima oportunidade para quem deseja praticar Flutter, Firebase e desenvolvimento multiplataforma.

Para contribuir:
1. 🍴 Faça um fork
2. 🌿 Crie uma branch (`git checkout -b feature/dark-mode`)
3. 💾 Commit suas mudanças (`git commit -m 'Adiciona modo escuro'`)
4. 🚀 Envie (`git push origin feature/dark-mode`)
5. 📥 Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 📬 Contato

Desenvolvido por **[Evalente82](https://github.com/evalente82)**  
💼 *Simplificando processos com tecnologia.*

<a href="https://github.com/evalente82">
  <img src="https://img.shields.io/badge/Ver%20Perfil%20no%20GitHub-181717?style=for-the-badge&logo=github" alt="GitHub Profile">
</a>

---

> ✨ *Gestão de escalas, feita simples. Em qualquer dispositivo, a qualquer hora.*

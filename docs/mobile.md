# InteraEdu — Mobile (Flutter)

## Visão Geral

O aplicativo móvel do InteraEdu é desenvolvido em **Flutter (Dart)**, seguindo **Clean Architecture**. É o principal ponto de acesso dos usuários à plataforma acadêmica.

---

## Propósito do Módulo

Oferecer uma experiência nativa de rede social acadêmica: login institucional com verificação por e-mail, feed de publicações, perfis de usuários, conexões e mensagens.

---

## Responsabilidades

- Autenticação (e-mail institucional + OTP + JWT)
- Visualização e criação de posts no feed (local e global)
- Gerenciamento de perfil do usuário
- Exploração e conexão com outros acadêmicos
- Mensagens em tempo real (chat)
- Gerenciamento de estado de autenticação e tokens

---

## Tecnologias Utilizadas

| Tecnologia | Finalidade |
|---|---|
| **Flutter 3 / Dart** | Framework principal |
| **http** | Requisições HTTP para a API |
| **SecureStorage** | Armazenamento seguro de tokens JWT |
| **Material Design 3** | Design system |

---

## Estrutura do Projeto

```
lib/
├── main.dart                       # Ponto de entrada da aplicação
├── app.dart                        # MaterialApp, roteamento, tema
├── core/                           # Infraestrutura compartilhada
│   ├── config/
│   │   └── app_config.dart         # URL da API, timeouts, flags de ambiente
│   ├── network/
│   │   ├── api_client.dart         # HTTP client com auth automático (Bearer JWT)
│   │   └── api_endpoints.dart      # Constantes de endpoints da API
│   ├── storage/
│   │   └── secure_storage.dart     # Leitura/escrita segura de access e refresh tokens
│   ├── theme/
│   │   ├── app_colors.dart         # Paleta de cores (verde/neutros)
│   │   ├── app_text_styles.dart    # Tipografia padronizada
│   │   └── app_theme.dart          # ThemeData Material 3
│   └── utils/                      # Utilitários gerais
├── domain/                         # Regras de negócio (independente de UI/infra)
│   ├── entities/                   # Modelos de domínio (User, Post, Profile, etc.)
│   └── repositories/               # Interfaces abstratas de repositório
├── data/                           # Implementações concretas
│   ├── models/                     # DTOs/modelos JSON da API
│   └── repositories/
│       ├── auth_repository_impl.dart   # Login, registro, OTP, tokens
│       └── feed_repository_impl.dart   # Fetch de feed e posts
└── presentation/                   # UI (Screens e Widgets)
    ├── auth/
    │   └── screens/
    │       ├── login_screen.dart       # Tela de login
    │       ├── register_screen.dart    # Tela de cadastro (e-mail)
    │       └── otp_screen.dart         # Tela de verificação OTP
    ├── feed/
    │   └── screens/
    │       └── feed_screen.dart        # Tela principal do feed
    └── onboarding/
        └── screens/                    # Telas de boas-vindas / onboarding
```

---

## Como Rodar

### Pré-requisitos

- **Flutter SDK** >= 3.11 (`flutter --version`)
- **Dart SDK** >= 3.0
- **Android Studio** ou **VS Code** com extensão Flutter
- Emulador Android/iOS *ou* dispositivo físico

### Instalação

```bash
# 1. Na raiz do projeto (onde está pubspec.yaml)
flutter pub get

# 2. Para verificar o ambiente
flutter doctor
```

### Variáveis de Ambiente / Configurações

Edite `lib/core/config/app_config.dart`:

```dart
// Modo de desenvolvimento (usa dados mock)
static const bool devMode = false;

// URL base da API Gateway
static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
// ou: 'http://localhost:3000/api/v1' para iOS simulator
// ou: 'http://<IP-LOCAL>:3000/api/v1' para dispositivo físico
```

### Comandos de Execução

```bash
# Rodar no emulador/dispositivo padrão
flutter run

# Rodar em dispositivo específico
flutter run -d <device-id>

# Listar dispositivos disponíveis
flutter devices

# Build APK de debug
flutter build apk --debug

# Build APK de release
flutter build apk --release
```

---

## Integração com Backend

### Fluxo de Autenticação

```
LoginScreen → AuthRepositoryImpl.login()
    → ApiClient.post('/auth/login')
    → Gateway (:3000) → Auth Service (:3001)
    ← { access_token, refresh_token }
    → SecureStorage.saveTokens()
    → Navega para FeedScreen
```

### Fluxo de Registro (3 etapas)

```
1. RegisterScreen   → POST /auth/register   (envia e-mail institucional)
2. OtpScreen        → POST /auth/verify-otp (confirma código)
3. OtpScreen        → POST /auth/complete-registration (senha + consentimento)
```

### Renovação de Token

O `ApiClient` **não implementa refresh automático ainda** — este é um ponto crítico a implementar (ver seção de tarefas).

---

## Convenções e Padrões

### Arquitetura (Clean Architecture)

```
Presentation → Domain ← Data
```

- **Presentation**: apenas UI, sem lógica de negócio
- **Domain**: entidades e interfaces, sem dependências externas
- **Data**: implementações de repositório, modelos JSON, API calls
- **Core**: infraestrutura compartilhada (cliente HTTP, tema, config)

### Padrões de Código

- Sempre nomear arquivos em `snake_case`
- Classes, enums e widgets em `PascalCase`
- Variáveis e métodos em `camelCase`
- Sempre usar `const` em widgets que não mudam
- Extrair widgets maiores que ~80 linhas em arquivos separados

### Convenção de Nomenclatura

| Tipo | Padrão | Exemplo |
|---|---|---|
| Screen | `*_screen.dart` | `login_screen.dart` |
| Widget | `*_widget.dart` | `post_card_widget.dart` |
| Repository Interface | `*_repository.dart` | `auth_repository.dart` |
| Repository Impl | `*_repository_impl.dart` | `auth_repository_impl.dart` |
| Model | `*_model.dart` | `user_model.dart` |
| Entity | `*_entity.dart` | `user_entity.dart` |

### Regras Importantes

- **NUNCA** chamar `ApiClient` diretamente de uma Screen — sempre via Repository
- **SEMPRE** tratar `ApiException` nos repositórios, convertendo para erros de domínio
- **SEMPRE** atualizar `api_endpoints.dart` ao adicionar novos endpoints
- Estado de autenticação deve ser gerenciado globalmente (não em widget local)
- Tokens **nunca** em memória ou SharedPreferences — usar SecureStorage

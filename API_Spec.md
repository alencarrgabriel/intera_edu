# Especificação da API (MVP) - InteraEdu

Baseada em RESTful JSON. Todos os endpoints privados requerem `Authorization: Bearer <JWT>`.

## 1. Autenticação (`/auth`)

*   **POST `/auth/register-init`**: Inicia o cadastro. Envia e-mail institucional e valida domínio. Dispara OTP.
*   **POST `/auth/verify-otp`**: Valida o código recebido por e-mail e retorna um token temporário.
*   **POST `/auth/complete-profile`**: Salva senha, habilidades e curso. Retorna o JWT final.
*   **POST `/auth/login`**: Login padrão com e-mail e senha.

## 2. Usuários e Perfis (`/users`)

*   **GET `/users/me`**: Retorna os dados do próprio usuário logado.
*   **PATCH `/users/me`**: Atualiza habilidades, período ou links.
*   **GET `/users/search?skill=python&institution=usp`**: Busca filtrada de estudantes.
*   **GET `/users/{id}/profile`**: Visualiza perfil público de outro usuário (respeitando Privacy Masking).

## 3. Feed Social (`/posts`)

*   **GET `/posts?scope=local`**: Retorna o feed da própria IES do usuário.
*   **GET `/posts?scope=global`**: Retorna o feed interuniversitário (incluindo algoritmo Force Exploration).
*   **POST `/posts`**: Cria uma nova postagem (Texto/Anexo).
*   **DELETE `/posts/{id}`**: Remove uma postagem própria.

## 4. Mensageria (`/messages`)

*   **GET `/chats`**: Lista os chats ativos (1:1 e grupos).
*   **POST `/chats/init`**: Inicia um novo chat com um usuário a partir do perfil dele.
*   **GET `/chats/{id}/messages`**: Carrega o histórico de mensagens de um chat.
*   **POST `/messages/send`**: Envia mensagem de texto ou arquivo via WebSocket/HTTP.

---

## 5. Códigos de Erro Padrão
*   `401 Unauthorized`: Token ausente ou inválido.
*   `403 Forbidden`: Domínio de e-mail não educacional ou perfil privado.
*   `422 Unprocessable Entity`: Falha na validação de campos (ex: e-mail inválido).

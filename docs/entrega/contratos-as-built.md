# Contratos HTTP As-Built

Inventário extraído da AST dos controllers da árvore de trabalho. Regenerar: `node .scripts/generate-as-built.cjs` (após `npm ci` em backend). As definições vinculadas são parte da especificação. A execução HTTP e os testes são descritos no relatório de validação.

Rotas de negócio são acessadas pelo gateway com prefixo `/api/v1`. As linhas abaixo mostram o caminho no serviço; gateway tem prefixo próprio. `@Public` dispensa o guard JWT, mas não necessariamente outras verificações (ex.: token de serviço em notifications/internal). O gateway encaminha a autenticação; os guards dos serviços a validam.

Status padrão é o declarado pelo Nest; handlers que manipulam `@Res`, lançam exceções ou retornam outro status prevalecem. Tipos inline e `any` não recebem automaticamente validação class-validator; os DTOs abaixo identificam os contratos que possuem validação declarativa.

| Serviço | Método | Caminho no serviço | Dispensa JWT via @Public | Status declarado | Handler e fonte |
|---|---|---|---|---|---|
| profile-service | GET | `/health` | sim | 200 (padrão Nest) | [HealthController.health](../../backend/shared/src/health.controller.ts) |
| feed-service | GET | `/health` | sim | 200 (padrão Nest) | [HealthController.health](../../backend/shared/src/health.controller.ts) |
| messaging-service | GET | `/health` | sim | 200 (padrão Nest) | [HealthController.health](../../backend/shared/src/health.controller.ts) |
| gateway | GET | `/health` | não marcado | 200 (padrão Nest) | [HealthController.health](../../backend/gateway/src/health.controller.ts) |
| gateway | GET | `/health/ready` | não marcado | 200 (padrão Nest) | [HealthController.readiness](../../backend/gateway/src/health.controller.ts) |
| gateway | ALL | `/*` | não marcado | 200 (padrão Nest) | [ProxyController.proxy](../../backend/gateway/src/proxy/proxy.controller.ts) |
| auth-service | POST | `/auth/register` | sim | HttpStatus.ACCEPTED | [AuthController.register](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/verify-otp` | sim | HttpStatus.OK | [AuthController.verifyOtp](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/complete-registration` | sim | HttpStatus.CREATED | [AuthController.completeRegistration](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/login` | sim | HttpStatus.OK | [AuthController.login](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/google` | sim | HttpStatus.OK | [AuthController.loginWithGoogle](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/forgot-password` | sim | HttpStatus.ACCEPTED | [AuthController.forgotPassword](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/reset-password` | sim | HttpStatus.OK | [AuthController.resetPassword](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/refresh` | sim | HttpStatus.OK | [AuthController.refresh](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/logout` | não marcado | HttpStatus.NO_CONTENT | [AuthController.logout](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/accept-terms` | não marcado | HttpStatus.OK | [AuthController.acceptTerms](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | POST | `/auth/revoke-consent` | não marcado | HttpStatus.OK | [AuthController.revokeConsent](../../backend/auth-service/src/auth/auth.controller.ts) |
| auth-service | GET | `/health` | sim | 200 (padrão Nest) | [HealthController.health](../../backend/auth-service/src/health.controller.ts) |
| auth-service | GET | `/institutions` | sim | 200 (padrão Nest) | [InstitutionController.list](../../backend/auth-service/src/institution/institution.controller.ts) |
| auth-service | POST | `/institutions` | não marcado | HttpStatus.CREATED | [InstitutionController.create](../../backend/auth-service/src/institution/institution.controller.ts) |
| auth-service | PATCH | `/institutions/:id/domains` | não marcado | 200 (padrão Nest) | [InstitutionController.patchDomains](../../backend/auth-service/src/institution/institution.controller.ts) |
| profile-service | GET | `/users/me/blocks` | não marcado | 200 (padrão Nest) | [BlocksController.list](../../backend/profile-service/src/blocks/blocks.controller.ts) |
| profile-service | POST | `/users/me/blocks/:userId` | não marcado | HttpStatus.CREATED | [BlocksController.block](../../backend/profile-service/src/blocks/blocks.controller.ts) |
| profile-service | DELETE | `/users/me/blocks/:userId` | não marcado | HttpStatus.OK | [BlocksController.unblock](../../backend/profile-service/src/blocks/blocks.controller.ts) |
| profile-service | GET | `/connections` | não marcado | 200 (padrão Nest) | [ConnectionsController.list](../../backend/profile-service/src/connections/connections.controller.ts) |
| profile-service | POST | `/connections` | não marcado | 201 (padrão Nest) | [ConnectionsController.create](../../backend/profile-service/src/connections/connections.controller.ts) |
| profile-service | PATCH | `/connections/:id` | não marcado | 200 (padrão Nest) | [ConnectionsController.update](../../backend/profile-service/src/connections/connections.controller.ts) |
| profile-service | DELETE | `/connections/:id` | não marcado | 200 (padrão Nest) | [ConnectionsController.remove](../../backend/profile-service/src/connections/connections.controller.ts) |
| profile-service | GET | `/users/me` | não marcado | 200 (padrão Nest) | [ProfileController.getMyProfile](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | PATCH | `/users/me` | não marcado | 200 (padrão Nest) | [ProfileController.updateMyProfile](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | POST | `/users/me/avatar` | não marcado | 201 (padrão Nest) | [ProfileController.uploadAvatar](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | DELETE | `/users/me` | não marcado | 200 (padrão Nest) | [ProfileController.deleteMyAccount](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | GET | `/users/me/data-export` | não marcado | 200 (padrão Nest) | [ProfileController.requestDataExport](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | GET | `/users/search` | não marcado | 200 (padrão Nest) | [ProfileController.searchUsers](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | GET | `/users/batch` | não marcado | 200 (padrão Nest) | [ProfileController.batchGet](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | GET | `/users/by-handles` | não marcado | 200 (padrão Nest) | [ProfileController.byHandles](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | GET | `/users/handle/:handle` | não marcado | 200 (padrão Nest) | [ProfileController.getByHandle](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | GET | `/users/:id` | não marcado | 200 (padrão Nest) | [ProfileController.getProfile](../../backend/profile-service/src/profile/profile.controller.ts) |
| profile-service | GET | `/skills` | não marcado | 200 (padrão Nest) | [SkillsController.list](../../backend/profile-service/src/skills/skills.controller.ts) |
| profile-service | GET | `/skills/search` | não marcado | 200 (padrão Nest) | [SkillsController.search](../../backend/profile-service/src/skills/skills.controller.ts) |
| profile-service | GET | `/users/me/suggestions` | não marcado | 200 (padrão Nest) | [SuggestionsController.list](../../backend/profile-service/src/suggestions/suggestions.controller.ts) |
| feed-service | GET | `/bookmarks` | não marcado | 200 (padrão Nest) | [BookmarksController.list](../../backend/feed-service/src/bookmarks/bookmarks.controller.ts) |
| feed-service | POST | `/posts/:id/bookmark` | não marcado | 201 (padrão Nest) | [BookmarksController.add](../../backend/feed-service/src/bookmarks/bookmarks.controller.ts) |
| feed-service | DELETE | `/posts/:id/bookmark` | não marcado | 200 (padrão Nest) | [BookmarksController.remove](../../backend/feed-service/src/bookmarks/bookmarks.controller.ts) |
| feed-service | GET | `/disciplines` | não marcado | 200 (padrão Nest) | [GroupsController.listDisciplines](../../backend/feed-service/src/groups/groups.controller.ts) |
| feed-service | POST | `/disciplines` | não marcado | 201 (padrão Nest) | [GroupsController.createDiscipline](../../backend/feed-service/src/groups/groups.controller.ts) |
| feed-service | GET | `/groups` | não marcado | 200 (padrão Nest) | [GroupsController.listGroups](../../backend/feed-service/src/groups/groups.controller.ts) |
| feed-service | POST | `/groups` | não marcado | 201 (padrão Nest) | [GroupsController.createGroup](../../backend/feed-service/src/groups/groups.controller.ts) |
| feed-service | GET | `/groups/:id` | não marcado | 200 (padrão Nest) | [GroupsController.getGroup](../../backend/feed-service/src/groups/groups.controller.ts) |
| feed-service | POST | `/groups/:id/join` | não marcado | 201 (padrão Nest) | [GroupsController.joinGroup](../../backend/feed-service/src/groups/groups.controller.ts) |
| feed-service | DELETE | `/groups/:id/join` | não marcado | 200 (padrão Nest) | [GroupsController.leaveGroup](../../backend/feed-service/src/groups/groups.controller.ts) |
| feed-service | GET | `/groups/:id/members` | não marcado | 200 (padrão Nest) | [GroupsController.listMembers](../../backend/feed-service/src/groups/groups.controller.ts) |
| feed-service | GET | `/groups/:id/materials` | não marcado | 200 (padrão Nest) | [MaterialsController.list](../../backend/feed-service/src/materials/materials.controller.ts) |
| feed-service | POST | `/groups/:id/materials` | não marcado | 201 (padrão Nest) | [MaterialsController.upload](../../backend/feed-service/src/materials/materials.controller.ts) |
| feed-service | GET | `/materials/:id/download` | não marcado | 200 (padrão Nest) | [MaterialsController.download](../../backend/feed-service/src/materials/materials.controller.ts) |
| feed-service | POST | `/materials/:id/rate` | não marcado | 201 (padrão Nest) | [MaterialsController.rate](../../backend/feed-service/src/materials/materials.controller.ts) |
| feed-service | DELETE | `/materials/:id` | não marcado | 200 (padrão Nest) | [MaterialsController.remove](../../backend/feed-service/src/materials/materials.controller.ts) |
| feed-service | GET | `/groups/:id/feed` | não marcado | 200 (padrão Nest) | [GroupFeedController.groupFeed](../../backend/feed-service/src/posts/group-feed.controller.ts) |
| feed-service | GET | `/posts` | não marcado | 200 (padrão Nest) | [PostsController.getFeed](../../backend/feed-service/src/posts/posts.controller.ts) |
| feed-service | POST | `/posts` | não marcado | 201 (padrão Nest) | [PostsController.createPost](../../backend/feed-service/src/posts/posts.controller.ts) |
| feed-service | GET | `/posts/:id` | não marcado | 200 (padrão Nest) | [PostsController.getPost](../../backend/feed-service/src/posts/posts.controller.ts) |
| feed-service | DELETE | `/posts/:id` | não marcado | 200 (padrão Nest) | [PostsController.deletePost](../../backend/feed-service/src/posts/posts.controller.ts) |
| feed-service | POST | `/posts/:id/reactions` | não marcado | 201 (padrão Nest) | [PostsController.addReaction](../../backend/feed-service/src/posts/posts.controller.ts) |
| feed-service | DELETE | `/posts/:id/reactions` | não marcado | 200 (padrão Nest) | [PostsController.removeReaction](../../backend/feed-service/src/posts/posts.controller.ts) |
| feed-service | GET | `/posts/:id/comments` | não marcado | 200 (padrão Nest) | [PostsController.getComments](../../backend/feed-service/src/posts/posts.controller.ts) |
| feed-service | POST | `/posts/:id/comments` | não marcado | 201 (padrão Nest) | [PostsController.addComment](../../backend/feed-service/src/posts/posts.controller.ts) |
| feed-service | POST | `/reports` | não marcado | HttpStatus.CREATED | [ReportsController.create](../../backend/feed-service/src/reports/reports.controller.ts) |
| feed-service | GET | `/reports` | não marcado | 200 (padrão Nest) | [ReportsController.listOpen](../../backend/feed-service/src/reports/reports.controller.ts) |
| feed-service | PATCH | `/reports/:id` | não marcado | 200 (padrão Nest) | [ReportsController.resolve](../../backend/feed-service/src/reports/reports.controller.ts) |
| feed-service | GET | `/stories` | não marcado | 200 (padrão Nest) | [StoriesController.list](../../backend/feed-service/src/stories/stories.controller.ts) |
| feed-service | GET | `/stories/mine` | não marcado | 200 (padrão Nest) | [StoriesController.mine](../../backend/feed-service/src/stories/stories.controller.ts) |
| feed-service | POST | `/stories` | não marcado | 201 (padrão Nest) | [StoriesController.create](../../backend/feed-service/src/stories/stories.controller.ts) |
| feed-service | POST | `/stories/:id/view` | não marcado | 201 (padrão Nest) | [StoriesController.view](../../backend/feed-service/src/stories/stories.controller.ts) |
| feed-service | DELETE | `/stories/:id` | não marcado | 200 (padrão Nest) | [StoriesController.remove](../../backend/feed-service/src/stories/stories.controller.ts) |
| feed-service | GET | `/tags` | não marcado | 200 (padrão Nest) | [TagsController.search](../../backend/feed-service/src/tags/tags.controller.ts) |
| feed-service | GET | `/tags/trending` | não marcado | 200 (padrão Nest) | [TagsController.trending](../../backend/feed-service/src/tags/tags.controller.ts) |
| feed-service | GET | `/tags/mine` | não marcado | 200 (padrão Nest) | [TagsController.mine](../../backend/feed-service/src/tags/tags.controller.ts) |
| feed-service | GET | `/tags/:slug` | não marcado | 200 (padrão Nest) | [TagsController.get](../../backend/feed-service/src/tags/tags.controller.ts) |
| feed-service | GET | `/tags/:slug/posts` | não marcado | 200 (padrão Nest) | [TagsController.posts](../../backend/feed-service/src/tags/tags.controller.ts) |
| feed-service | POST | `/tags/:slug/follow` | não marcado | 201 (padrão Nest) | [TagsController.follow](../../backend/feed-service/src/tags/tags.controller.ts) |
| feed-service | DELETE | `/tags/:slug/follow` | não marcado | 200 (padrão Nest) | [TagsController.unfollow](../../backend/feed-service/src/tags/tags.controller.ts) |
| messaging-service | GET | `/chats` | não marcado | 200 (padrão Nest) | [ChatsController.listChats](../../backend/messaging-service/src/chats/chats.controller.ts) |
| messaging-service | POST | `/chats` | não marcado | 201 (padrão Nest) | [ChatsController.createChat](../../backend/messaging-service/src/chats/chats.controller.ts) |
| messaging-service | GET | `/chats/:id` | não marcado | 200 (padrão Nest) | [ChatsController.getChat](../../backend/messaging-service/src/chats/chats.controller.ts) |
| messaging-service | PATCH | `/chats/:id` | não marcado | 200 (padrão Nest) | [ChatsController.updateChat](../../backend/messaging-service/src/chats/chats.controller.ts) |
| messaging-service | GET | `/chats/:id/messages` | não marcado | 200 (padrão Nest) | [ChatsController.getMessages](../../backend/messaging-service/src/chats/chats.controller.ts) |
| messaging-service | POST | `/chats/:id/messages` | não marcado | 201 (padrão Nest) | [ChatsController.sendMessage](../../backend/messaging-service/src/chats/chats.controller.ts) |
| messaging-service | POST | `/chats/:id/members` | não marcado | 201 (padrão Nest) | [ChatsController.addMember](../../backend/messaging-service/src/chats/chats.controller.ts) |
| messaging-service | DELETE | `/chats/:id/members/:userId` | não marcado | 200 (padrão Nest) | [ChatsController.removeMember](../../backend/messaging-service/src/chats/chats.controller.ts) |
| messaging-service | GET | `/notifications` | não marcado | 200 (padrão Nest) | [NotificationsController.list](../../backend/messaging-service/src/notifications/notifications.controller.ts) |
| messaging-service | PATCH | `/notifications/:id/read` | não marcado | HttpStatus.OK | [NotificationsController.markRead](../../backend/messaging-service/src/notifications/notifications.controller.ts) |
| messaging-service | PATCH | `/notifications/read-all` | não marcado | HttpStatus.OK | [NotificationsController.markAllRead](../../backend/messaging-service/src/notifications/notifications.controller.ts) |
| messaging-service | POST | `/notifications/internal` | sim | 201 (padrão Nest) | [NotificationsController.createInternal](../../backend/messaging-service/src/notifications/notifications.controller.ts) |

## Entradas declaradas por handler

| Handler | Parâmetros, tipos e decorators |
|---|---|
| profile-service: HealthController.health | `—` |
| feed-service: HealthController.health | `—` |
| messaging-service: HealthController.health | `—` |
| gateway: HealthController.health | `—` |
| gateway: HealthController.readiness | `—` |
| gateway: ProxyController.proxy | `@Req() req: Request; @Res() res: Response` |
| auth-service: AuthController.register | `@Body() dto: RegisterDto` |
| auth-service: AuthController.verifyOtp | `@Body() dto: VerifyOtpDto` |
| auth-service: AuthController.completeRegistration | `@Body() dto: CompleteRegistrationDto` |
| auth-service: AuthController.login | `@Body() dto: LoginDto` |
| auth-service: AuthController.loginWithGoogle | `@Body() dto: GoogleLoginDto` |
| auth-service: AuthController.forgotPassword | `@Body() dto: ForgotPasswordDto` |
| auth-service: AuthController.resetPassword | `@Body() dto: ResetPasswordDto` |
| auth-service: AuthController.refresh | `@Body() dto: RefreshTokenDto` |
| auth-service: AuthController.logout | `@Body() dto: RefreshTokenDto` |
| auth-service: AuthController.acceptTerms | `@CurrentUser() user: JwtPayload` |
| auth-service: AuthController.revokeConsent | `@CurrentUser() user: JwtPayload` |
| auth-service: HealthController.health | `—` |
| auth-service: InstitutionController.list | `—` |
| auth-service: InstitutionController.create | `@CurrentUser() user: JwtPayload; @Body() dto: { name: string; slug: string; domains: string[] }` |
| auth-service: InstitutionController.patchDomains | `@CurrentUser() user: JwtPayload; @Param('id') id: string; @Body() body: { add?: string[]; remove?: string[] }` |
| profile-service: BlocksController.list | `@CurrentUser() user: JwtPayload` |
| profile-service: BlocksController.block | `@Param('userId') blockedId: string; @CurrentUser() user: JwtPayload` |
| profile-service: BlocksController.unblock | `@Param('userId') blockedId: string; @CurrentUser() user: JwtPayload` |
| profile-service: ConnectionsController.list | `@CurrentUser() user: JwtPayload; @Query('status') status?: string; @Query('direction') direction?: string` |
| profile-service: ConnectionsController.create | `@CurrentUser() user: JwtPayload; @Body() dto: CreateConnectionDto` |
| profile-service: ConnectionsController.update | `@CurrentUser() user: JwtPayload; @Param('id') id: string; @Body() dto: UpdateConnectionDto` |
| profile-service: ConnectionsController.remove | `@CurrentUser() user: JwtPayload; @Param('id') id: string` |
| profile-service: ProfileController.getMyProfile | `@CurrentUser() user: JwtPayload` |
| profile-service: ProfileController.updateMyProfile | `@CurrentUser() user: JwtPayload; @Body() dto: UpdateProfileDto` |
| profile-service: ProfileController.uploadAvatar | `@CurrentUser() user: JwtPayload; @UploadedFile() file: Express.Multer.File` |
| profile-service: ProfileController.deleteMyAccount | `@CurrentUser() user: JwtPayload` |
| profile-service: ProfileController.requestDataExport | `@CurrentUser() user: JwtPayload` |
| profile-service: ProfileController.searchUsers | `@Query() query: any; @CurrentUser() user: JwtPayload` |
| profile-service: ProfileController.batchGet | `@Query('ids') ids: string` |
| profile-service: ProfileController.byHandles | `@Query('handles') handles: string` |
| profile-service: ProfileController.getByHandle | `@Param('handle') handle: string; @CurrentUser() user: JwtPayload` |
| profile-service: ProfileController.getProfile | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| profile-service: SkillsController.list | `@Query('category') category?: string` |
| profile-service: SkillsController.search | `@Query('q') q: string` |
| profile-service: SuggestionsController.list | `@CurrentUser() user: JwtPayload` |
| feed-service: BookmarksController.list | `@CurrentUser() user: JwtPayload; @Headers('authorization') auth: string` |
| feed-service: BookmarksController.add | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: BookmarksController.remove | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: GroupsController.listDisciplines | `@CurrentUser() user: JwtPayload; @Query('q') q?: string` |
| feed-service: GroupsController.createDiscipline | `@Body() dto: any; @CurrentUser() user: JwtPayload` |
| feed-service: GroupsController.listGroups | `@CurrentUser() user: JwtPayload; @Query('mine') mine?: string; @Query('q') q?: string` |
| feed-service: GroupsController.createGroup | `@Body() dto: any; @CurrentUser() user: JwtPayload` |
| feed-service: GroupsController.getGroup | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: GroupsController.joinGroup | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: GroupsController.leaveGroup | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: GroupsController.listMembers | `@Param('id') id: string` |
| feed-service: MaterialsController.list | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: MaterialsController.upload | `@Param('id') id: string; @UploadedFile() file: Express.Multer.File \| undefined; @Body() body: any; @CurrentUser() user: JwtPayload` |
| feed-service: MaterialsController.download | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: MaterialsController.rate | `@Param('id') id: string; @Body() body: any; @CurrentUser() user: JwtPayload` |
| feed-service: MaterialsController.remove | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: GroupFeedController.groupFeed | `@Param('id') id: string; @Query('cursor') cursor: string; @Query('limit') limit: number; @CurrentUser() user: JwtPayload; @Headers('authorization') authToken: string` |
| feed-service: PostsController.getFeed | `@Query('scope') scope: string; @Query('cursor') cursor: string; @Query('limit') limit: number; @CurrentUser() user: JwtPayload; @Headers('authorization') authToken: string` |
| feed-service: PostsController.createPost | `@Body() dto: CreatePostDto; @UploadedFile() file: Express.Multer.File \| undefined; @CurrentUser() user: JwtPayload; @Headers('authorization') authToken: string` |
| feed-service: PostsController.getPost | `@Param('id') id: string` |
| feed-service: PostsController.deletePost | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: PostsController.addReaction | `@Param('id') id: string; @Body() dto: any; @CurrentUser() user: JwtPayload` |
| feed-service: PostsController.removeReaction | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: PostsController.getComments | `@Param('id') id: string; @Query('cursor') cursor: string; @Headers('authorization') authToken: string` |
| feed-service: PostsController.addComment | `@Param('id') id: string; @Body() dto: any; @CurrentUser() user: JwtPayload; @Headers('authorization') authToken: string` |
| feed-service: ReportsController.create | `@CurrentUser() user: JwtPayload; @Body() dto: { target_type: string; target_id: string; reason?: string; description?: string; }` |
| feed-service: ReportsController.listOpen | `—` |
| feed-service: ReportsController.resolve | `@CurrentUser() user: JwtPayload; @Param('id') id: string; @Body() body: { action: 'resolve' \| 'dismiss' }` |
| feed-service: StoriesController.list | `@CurrentUser() user: JwtPayload; @Headers('authorization') auth: string` |
| feed-service: StoriesController.mine | `@CurrentUser() user: JwtPayload` |
| feed-service: StoriesController.create | `@UploadedFile() file: Express.Multer.File \| undefined; @Body() body: any; @CurrentUser() user: JwtPayload` |
| feed-service: StoriesController.view | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: StoriesController.remove | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| feed-service: TagsController.search | `@Query('q') q?: string` |
| feed-service: TagsController.trending | `@CurrentUser() user: JwtPayload` |
| feed-service: TagsController.mine | `@CurrentUser() user: JwtPayload` |
| feed-service: TagsController.get | `@Param('slug') slug: string; @CurrentUser() user: JwtPayload` |
| feed-service: TagsController.posts | `@Param('slug') slug: string; @Query('cursor') cursor: string; @CurrentUser() user: JwtPayload; @Headers('authorization') auth: string` |
| feed-service: TagsController.follow | `@Param('slug') slug: string; @CurrentUser() user: JwtPayload` |
| feed-service: TagsController.unfollow | `@Param('slug') slug: string; @CurrentUser() user: JwtPayload` |
| messaging-service: ChatsController.listChats | `@Query('type') type: string; @Query('cursor') cursor: string; @CurrentUser() user: JwtPayload` |
| messaging-service: ChatsController.createChat | `@Body() dto: any; @CurrentUser() user: JwtPayload` |
| messaging-service: ChatsController.getChat | `@Param('id') id: string; @CurrentUser() user: JwtPayload` |
| messaging-service: ChatsController.updateChat | `@Param('id') id: string; @Body() dto: any; @CurrentUser() user: JwtPayload` |
| messaging-service: ChatsController.getMessages | `@Param('id') id: string; @Query('cursor') cursor: string; @Query('limit') limit: number; @CurrentUser() user: JwtPayload` |
| messaging-service: ChatsController.sendMessage | `@Param('id') id: string; @Body() dto: any; @UploadedFile() file: Express.Multer.File \| undefined; @CurrentUser() user: JwtPayload` |
| messaging-service: ChatsController.addMember | `@Param('id') id: string; @Body() dto: any; @CurrentUser() user: JwtPayload` |
| messaging-service: ChatsController.removeMember | `@Param('id') id: string; @Param('userId') userId: string; @CurrentUser() user: JwtPayload` |
| messaging-service: NotificationsController.list | `@CurrentUser() user: JwtPayload; @Query('unread') unread?: string` |
| messaging-service: NotificationsController.markRead | `@CurrentUser() user: JwtPayload; @Param('id') id: string` |
| messaging-service: NotificationsController.markAllRead | `@CurrentUser() user: JwtPayload` |
| messaging-service: NotificationsController.createInternal | `@Body() body: any; @Headers('x-internal-token') token?: string` |

## DTOs e regras de validação

As definições abaixo são extraídas do código entregue; para corpos inline, consulte a assinatura e o controller correspondente.

### backend/shared/src/dto/error-response.dto.ts

[backend/shared/src/dto/error-response.dto.ts](../../backend/shared/src/dto/error-response.dto.ts)

```typescript
export class ErrorResponseDto {
  error: {
    code: string;
    message: string;
    status: number;
    details?: Array<{ field: string; message: string }>;
    request_id?: string;
    timestamp: string;
  };

  static create(
    code: string,
    message: string,
    status: number,
    details?: Array<{ field: string; message: string }>,
    requestId?: string,
  ): ErrorResponseDto {
    return {
      error: {
        code,
        message,
        status,
        details,
        request_id: requestId,
        timestamp: new Date().toISOString(),
      },
    };
  }
}
```

### backend/shared/src/dto/pagination.dto.ts

[backend/shared/src/dto/pagination.dto.ts](../../backend/shared/src/dto/pagination.dto.ts)

```typescript
import { IsOptional, IsInt, Min, Max, IsString } from 'class-validator';
import { Type } from 'class-transformer';

export class PaginationDto {
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}
```

### backend/auth-service/src/auth/dto/complete-registration.dto.ts

[backend/auth-service/src/auth/dto/complete-registration.dto.ts](../../backend/auth-service/src/auth/dto/complete-registration.dto.ts)

```typescript
import {
  IsString,
  IsNotEmpty,
  MinLength,
  MaxLength,
  Matches,
  ValidateNested,
  IsArray,
  IsOptional,
} from 'class-validator';
import { Type } from 'class-transformer';

class ConsentDto {
  @IsString()
  @IsNotEmpty()
  terms_version: string;

  @IsString()
  @IsNotEmpty()
  privacy_version: string;
}

export class CompleteRegistrationDto {
  @IsString()
  @IsNotEmpty()
  temporary_token: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/, {
    message: 'Password must contain uppercase, lowercase, number, and special character',
  })
  password: string;

  @IsString()
  @IsNotEmpty()
  full_name: string;

  @IsString()
  @IsOptional()
  course?: string;

  @IsOptional()
  period?: number;

  @IsArray()
  @IsOptional()
  skill_ids?: string[];

  @ValidateNested()
  @Type(() => ConsentDto)
  consent: ConsentDto;
}
```

### backend/auth-service/src/auth/dto/forgot-password.dto.ts

[backend/auth-service/src/auth/dto/forgot-password.dto.ts](../../backend/auth-service/src/auth/dto/forgot-password.dto.ts)

```typescript
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

export class ForgotPasswordDto {
  @IsEmail()
  email: string;
}

export class ResetPasswordDto {
  @IsEmail()
  email: string;

  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @MinLength(8)
  new_password: string;
}
```

### backend/auth-service/src/auth/dto/google-login.dto.ts

[backend/auth-service/src/auth/dto/google-login.dto.ts](../../backend/auth-service/src/auth/dto/google-login.dto.ts)

```typescript
import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleLoginDto {
  /// ID Token JWT devolvido pelo Google Identity Services no front-end.
  @IsString()
  @IsNotEmpty()
  id_token: string;
}
```

### backend/auth-service/src/auth/dto/login.dto.ts

[backend/auth-service/src/auth/dto/login.dto.ts](../../backend/auth-service/src/auth/dto/login.dto.ts)

```typescript
import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

export class LoginDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  password: string;
}
```

### backend/auth-service/src/auth/dto/refresh-token.dto.ts

[backend/auth-service/src/auth/dto/refresh-token.dto.ts](../../backend/auth-service/src/auth/dto/refresh-token.dto.ts)

```typescript
import { IsString, IsNotEmpty } from 'class-validator';

export class RefreshTokenDto {
  @IsString()
  @IsNotEmpty()
  refresh_token: string;
}
```

### backend/auth-service/src/auth/dto/register.dto.ts

[backend/auth-service/src/auth/dto/register.dto.ts](../../backend/auth-service/src/auth/dto/register.dto.ts)

```typescript
import { IsEmail, IsNotEmpty } from 'class-validator';

export class RegisterDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;
}
```

### backend/auth-service/src/auth/dto/verify-otp.dto.ts

[backend/auth-service/src/auth/dto/verify-otp.dto.ts](../../backend/auth-service/src/auth/dto/verify-otp.dto.ts)

```typescript
import { IsEmail, IsNotEmpty, IsString, Length } from 'class-validator';

export class VerifyOtpDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @Length(6, 6)
  code: string;
}
```

### backend/profile-service/src/connections/dto/create-connection.dto.ts

[backend/profile-service/src/connections/dto/create-connection.dto.ts](../../backend/profile-service/src/connections/dto/create-connection.dto.ts)

```typescript
import { IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateConnectionDto {
  @IsUUID()
  addressee_id: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}
```

### backend/profile-service/src/connections/dto/update-connection.dto.ts

[backend/profile-service/src/connections/dto/update-connection.dto.ts](../../backend/profile-service/src/connections/dto/update-connection.dto.ts)

```typescript
import { IsIn } from 'class-validator';

export class UpdateConnectionDto {
  @IsIn(['accept', 'reject'])
  action: 'accept' | 'reject';
}
```

### backend/profile-service/src/profile/dto/update-profile.dto.ts

[backend/profile-service/src/profile/dto/update-profile.dto.ts](../../backend/profile-service/src/profile/dto/update-profile.dto.ts)

```typescript
import { IsInt, IsOptional, IsString, IsUrl, MaxLength, Min, IsIn, IsArray, Matches } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(255)
  full_name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(48)
  @Matches(/^[a-z0-9_]+$/, { message: 'handle só aceita a-z, 0-9 e _' })
  handle?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  bio?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  course?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  period?: number;

  @IsOptional()
  @IsIn(['public', 'local_only', 'private'])
  privacy_level?: 'public' | 'local_only' | 'private';

  @IsOptional()
  @IsUrl()
  avatar_url?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  skill_ids?: string[];
}
```

### backend/feed-service/src/posts/dto/create-post.dto.ts

[backend/feed-service/src/posts/dto/create-post.dto.ts](../../backend/feed-service/src/posts/dto/create-post.dto.ts)

```typescript
import { IsArray, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreatePostDto {
  @IsString()
  @MaxLength(5000)
  content: string;

  @IsOptional()
  @IsIn(['local', 'global'])
  scope?: 'local' | 'global';

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  media_urls?: string[];
}
```

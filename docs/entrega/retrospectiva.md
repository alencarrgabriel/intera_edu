# Retrospectiva — InteraEdu

**Responsável:** Davi Vieira  
**Ferramentas de IA utilizadas:** Claude e ChatGPT

## Experiência de desenvolvimento

O InteraEdu foi minha primeira experiência desenvolvendo uma aplicação mobile. A principal dificuldade foi lidar com uma complexidade maior do que eu esperava. Além das telas, foi necessário compreender a relação entre estado da interface, autenticação, comunicação com o backend, configuração do ambiente e execução em dispositivos.

Utilizei Claude e ChatGPT durante o projeto. A experiência mostrou que o apoio de agentes de IA precisa ser acompanhado de entendimento do código e validação prática. Ter uma funcionalidade descrita ou implementada não garante que o fluxo completo esteja pronto para uso.

## Uso de IA no fluxo SDD

Na preparação da entrega, o trabalho assistido por IA produziu testes automatizados, relatórios de cobertura, revisão de configuração e uma especificação As-Built baseada nos fontes. Também ajudou a identificar diferenças entre a documentação anterior e a implementação, como o provedor de envio de OTP e as consultas entre schemas.

O ganho de produtividade observado nesta etapa está na capacidade de organizar verificações e produzir artefatos de forma repetível. Não foram coletadas medições de tempo que permitam afirmar um percentual de ganho, nem um experimento controlado para comparar Claude e ChatGPT.

## Dificuldades e lições aprendidas

- Aprender desenvolvimento mobile exigiu compreender o aplicativo como um conjunto de componentes, incluindo serviços e ambiente, além da interface.
- A aprovação dos testes precisa ser interpretada junto com o escopo e a cobertura: todos os casos passarem não significa que todo o sistema foi testado.
- A documentação precisa refletir o que o código realmente faz; funcionalidades planejadas devem permanecer identificadas como pendentes.
- Arquivos gerados, configurações locais e segredos precisam ficar fora do versionamento. A preparação da release encontrou artefatos compilados misturados aos fontes e incluiu sua limpeza.
- Governança envolve uma branch principal protegida, checks obrigatórios, revisão e identificação do commit liberado. A IA auxilia a preparação, mas a responsabilidade pelo aceite continua sendo humana.

## Avaliação final

O projeto ampliou meu entendimento sobre a complexidade de uma aplicação mobile e sobre a importância de unir especificação, implementação e evidência de testes. Para trabalhos futuros, a principal melhoria é estruturar desde o início os testes, a documentação e os critérios de aceite, mantendo pequenas entregas verificáveis.

Texto preparado a partir do relato de Davi Vieira e dos artefatos desta etapa. Deve ser revisado pelo responsável antes da entrega, especialmente as conclusões qualitativas sobre produtividade e aprendizado.

# Duelo 1v1 no Roblox

Versão para Roblox do modo 1 v 1 do Treino de Mira (`1v1.html`), com as mesmas regras e o mesmo galpão.

## Abrir e testar

1. Baixe o arquivo **`Duelo1v1.rbxlx`** desta pasta.
2. No **Roblox Studio**: *File → Open from File…* e escolha o arquivo.
3. Aperte **Play** (F5). Clique em **Contra Bot** para jogar sozinho.
4. Para testar **Contra Player** no Studio: aba *Test* → em *Clients and Servers* escolha **2 Players** → **Start**.
   Nas duas janelas que abrirem, clique em **Contra Player**.
5. Para publicar: *File → Publish to Roblox*. Para jogar com um amigo, os dois entram no mesmo servidor
   (convite pela lista de amigos ou servidor privado) e clicam em Contra Player.

Se algo der errado, abra *View → Output* e copie as linhas vermelhas.

## Regras (iguais ao jogo web)

- 3 vidas por rodada. Tiro no peito tira 1, na cabeça tira 3.
- Zerou as vidas do outro, ganha 1 ponto. Primeiro a 10 vence.
- Contagem 3 → 0 antes de cada rodada (ninguém anda durante a contagem).
- Pistola semiautomática: ~6,7 tiros/s, pente de 12, recarga de 1,75 s.
- Correndo, o tiro abre muito; andando com Shift abre pouco; parado é cravado.

Controles: WASD andar · Shift andar devagar · Clique atirar · R recarregar · P menu da partida.

## Como funciona

| Arquivo | O que faz |
| --- | --- |
| `src/shared/Config.luau` | Regras, dificuldades do bot, planta do mapa (em metros) e conversão para studs |
| `src/server/MapBuilder.luau` | Monta o galpão por script: chão, paredes, corredores, caixas, vigas |
| `src/server/Bot.luau` | Bot em cápsula amarela: reação, strafe, mira por dificuldade e busca com PathfindingService |
| `src/server/Main.server.luau` | Partida, rodadas, placar, munição e validação dos tiros |
| `src/client/Client.client.luau` | Telas, placar, mira, pistola em 1ª pessoa, traçantes e marcas de tiro |

- **O servidor decide tudo**: o jogador só envia "atirei daqui, nesta direção". O servidor confere cadência e munição,
  aplica o erro de mira pela velocidade que ele mesmo vê e faz o raio. Isso evita trapaça simples.
- Chapéus e acessórios não seguram tiro; só a cabeça (`Head`) conta como tiro na cabeça.
- Uma partida por servidor. Quem entra com uma partida rolando espera ela acabar.

## Diferenças do jogo web

- **Sensibilidade**: o valor do menu multiplica a sensibilidade de câmera do Roblox. Não dá para copiar
  exatamente os cm/360° do CS2/Valorant, porque o Roblox aplica a configuração dele por cima.
- **Contra Player** não usa link: os dois precisam estar no mesmo servidor.
- **Sem sons** por enquanto (o Roblox exige sons enviados como asset). Dá para adicionar IDs de som depois.
- **Sem controles de celular** por enquanto.
- A pistola na tela pode atravessar a parede quando você encosta nela (no Roblox não há uma câmera separada para a arma).

## Desenvolver com Rojo (opcional)

Os scripts são a fonte; o `.rbxlx` é gerado a partir deles:

```bash
rojo build default.project.json -o Duelo1v1.rbxlx
```

Com o plugin do Rojo no Studio, `rojo serve` sincroniza as mudanças ao vivo.

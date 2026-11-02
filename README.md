# Treino de Mira

Treino de mira no navegador, em um único arquivo (`index.html`), sem instalar nada.
Abra o arquivo no navegador ou publique a pasta no GitHub Pages.

## Como usar

1. Abra `index.html`.
2. Escolha o jogo (Counter-Strike 2 ou Valorant), a sensibilidade e o DPI do mouse.
   A arena usa a mesma conta do jogo (graus por contagem do mouse e campo de visão),
   então a mão se comporta igual.
3. Escolha um treino na barra lateral e aperte **Iniciar treino** (ou `Espaço`).

O mouse fica preso na arena durante o treino. `Esc` pausa e `R` reinicia.

## Treinos

| Treino | O que treina |
| --- | --- |
| Clique Rápido | Uma bolinha por vez em qualquer lugar da arena |
| Gridshot | Três bolinhas na tela ao mesmo tempo |
| Micro Ajuste | Bolinhas pequenas perto do centro, para correções curtas |
| Flick Longo | Bolinha alternando entre as bordas esquerda e direita |
| Reflexo | Bolinhas que somem em 1,2 s |
| Alvo Móvel | Bolinhas atravessando a arena; é preciso antecipar o movimento |
| Rastreio | Segure o clique e mantenha a mira na bolinha enquanto ela muda de direção |
| Bonecos 3D | Arena 3D com bonecos amarelos atrás de uma mureta, pistola e mão na tela; derrube um e outro aparece |

## Bonecos 3D

Modo em primeira pessoa feito com [Three.js](https://threejs.org) (carregado do CDN só quando o modo é escolhido,
então precisa de internet). A câmera usa o campo de visão do jogo escolhido (CS2 ou Valorant) e gira com a mesma
conta de sensibilidade, então o movimento da mão é igual ao do jogo. Três bonecos ficam na plataforma, alguns andando
para os lados; cada abate faz outro surgir. Tiro na cabeça aparece com marcador vermelho e conta em "Na cabeça".

## Resultados

- Acertos, precisão, tempo médio por alvo, melhor sequência e erros.
- **Centralização**: quanto mais perto do centro da bolinha você clica, maior.
- **Rastreio**: pontos (décimos de segundo com a mira na bolinha), porcentagem do tempo na mira e maior trecho contínuo.
- Recorde por treino, duração e tamanho do alvo.
- Gráfico das últimas partidas, com a média das últimas 10 para acompanhar a evolução.

## Opções

Duração (30 s, 1 min, 2 min), tamanho do alvo, cor e tamanho da mira, som de acerto,
tela cheia ao iniciar e compensação de zoom do sistema. Tudo fica salvo no navegador.

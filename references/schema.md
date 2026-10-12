# Schema iso3d (versão 1)

Dois tipos de arquivo JSON:

- **Modelo** (`models/<id>.json`): descreve um tipo de equipamento uma vez só, com dimensões, faces, portas, slots e placas. Não tem estado, posição ou cabos.
- **Dashboard** (`<nome>.json`): monta um local real com racks, equipamentos (instâncias de modelos), cabos e o estado das portas.

Todas as medidas são em **milímetros**. É isso que permite misturar equipamentos de fabricantes diferentes na mesma cena com a proporção certa.

## Sumário
1. Sistema de coordenadas
2. Modelo de equipamento
3. Itens decorativos
4. Portas
5. Slots e placas
6. Dashboard
7. Estado e métricas (alimentação de dados)
8. Referências de porta
9. Vocabulários

---

## 1. Sistema de coordenadas

**No mundo**, X cresce para a direita, Y para cima e Z para o fundo. A frente dos equipamentos olha para −Z.

**Em cada face**, a origem fica no canto superior esquerdo *de quem olha para aquela face*. `x` cresce para a direita e `y` para baixo. Exemplos:

| Face    | Largura × altura | Origem (vista de frente para a face) |
|---------|------------------|--------------------------------------|
| `front` | w × h            | canto superior esquerdo da frente     |
| `rear`  | w × h            | canto superior esquerdo visto por trás (ou seja, o lado direito da frente) |
| `left`  | d × h            | canto superior traseiro da lateral esquerda |
| `right` | d × h            | canto superior frontal da lateral direita |
| `top`   | w × d            | canto traseiro esquerdo do topo; `y` cresce em direção à frente |

As coordenadas de porta e de item são sempre as do **canto superior esquerdo** do elemento na face.

## 2. Modelo de equipamento

```jsonc
{
  "id": "huawei-ma5600t",            // obrigatório; kebab-case; igual ao nome do arquivo
  "vendor": "Huawei",
  "name": "SmartAX MA5600T",
  "category": "olt",                 // olt | onu | switch | router | dio | patch-panel | server | firewall | radio | pdu | ups | dwdm | cpe | other
  "size": { "w": 442, "h": 447, "d": 283 },   // obrigatório; corpo sem as orelhas de rack (use o valor do datasheet; 19" fica entre 430 e 450 mm, ETSI/23" vai até ~540)
  "rackUnits": 10,                   // opcional; se faltar, calcula h/44,45
  "body": "light",                   // light | dark | white | black (cor do chassi)
  "portLabel": "0/{slot}/{port}",    // opcional; nome exibido das portas de placa (padrão "{slot}/{port}")
  "faces": {
    "front": { "items": [ /* itens decorativos */ ] },
    "rear":  { "items": [] }, "top": { "items": [] }, "left": { "items": [] }, "right": { "items": [] }
  },
  "ports": [ /* portas fixas, ver seção 4 */ ],
  "slots": [ /* ver seção 5 */ ],
  "cards": { /* tipos de placa, ver seção 5 */ },
  "slotFiller": true,                // desenha tampa cega em slot vazio
  "source": {
    "basis": ["datasheet", "photo", "description", "estimate"],
    "refs": ["https://…/datasheet.pdf"],
    "confidence": "alta | média | baixa",
    "notes": "O que foi medido, o que foi estimado e o que foi estilizado.",
    "questions": [                   // pendências que o usuário pode resolver; o painel as mostra ao clicar no equipamento
      "Numeração das RJ45: ímpar em cima ou 1-12 em cima? (foto da serigrafia)",
      "Traseira sem foto: posição das fontes estimada"
    ]
  }
}
```

## 3. Itens decorativos (`faces.<face>.items[]`, `cards.<tipo>.items[]`)

Os itens ficam relativos à face, ou ao slot quando estão dentro de uma placa.

| type      | Campos                                               | Uso |
|-----------|------------------------------------------------------|-----|
| `rect`    | x, y, w, h, r?, fill?, stroke?                       | painel, baia de disco, tampa; sem `fill` vira cinza-escuro |
| `grille`  | x, y, w, h                                           | grade de ventilação com fendas verticais |
| `perf`    | x, y, w, h                                           | chapa perfurada (furos redondos) |
| `hex`     | x, y, w, h                                           | colmeia (servidores, fontes) |
| `slits`   | x, y, w, h                                           | fendas horizontais (laterais) |
| `screw`   | x, y (centro), r?                                    | parafuso, botão |
| `handle`  | x, y, w, h                                           | puxador, ejetor |
| `display` | x, y, w, h, text?, size?                             | LCD |
| `led`     | x, y (centro), r?, color? (`ok`, `alarm`, `down`, `disabled` ou hex) | LED fixo de painel |
| `label`   | x, y (linha de base), text, size? (mm, padrão 3,2), anchor? (`start`/`middle`/`end`), rotate? (graus), color? | serigrafia |
| `logo`    | igual a `label`, em fonte display (padrão 6 mm)      | nome do produto |

Não use marcas registradas como imagem. Escreva o nome do produto como texto em `logo`.

## 4. Portas (`ports[]` e `cards.<tipo>.ports[]`)

```jsonc
{ "id": "xe-0/0/0",   // obrigatório; igual ao nome na CLI do fabricante (é a chave que liga o dado ao desenho)
  "type": "sfp+",     // ver vocabulário
  "face": "front",    // só em portas fixas; em placas vale a face do slot
  "x": 232, "y": 17,  // canto superior esquerdo, em mm
  "w": 13.7, "h": 9.4,// opcional; o padrão vem do tipo
  "rotate": 90,       // opcional; porta em pé (gaiolas SFP verticais)
  "role": "uplink",   // pon | uplink | access | lan | wan | mgmt | console | power | patch | radio | generic
  "speed": "10GE",    // texto livre
  "label": "TE1",     // opcional; nome exibido em painel e tabela, quando é diferente do id
  "short": "1",       // opcional; texto curto (até 4 caracteres) desenhado DENTRO da porta
  "showLabel": false  // esconde o texto desenhado dentro da porta
}
```

Texto dentro da porta: se não houver `short`, o motor usa os dígitos finais do `id` (`ether12` → `12`, `sfp-sfpplus3` → `3`, `xe-0/0/7` → `7`). Se o `id` não terminar em dígitos, usa o próprio `id` quando ele tiver até 3 caracteres (`con`, `eth`); senão, não desenha nada. Use `short` quando a serigrafia real for diferente, por exemplo `"S1"` para a sfp28-1 de um MikroTik. Não use `label` para isso, porque o `label` aparece na tabela e precisa continuar inequívoco.

Tamanho padrão da abertura por tipo (largura × altura, em mm):

| type | mm | type | mm |
|------|----|------|----|
| rj45, console, mgmt, e1 | 11,7 × 10 | sc, sc-apc | 9,5 × 9,5 |
| sfp, sfp+, sfp28 | 13,7 × 9,4 | lc | 6,3 × 6,3 |
| qsfp, qsfp+, qsfp28 | 18,4 × 9,4 | lc-duplex | 12,7 × 6,3 |
| qsfp-dd | 18,4 × 11 | usb / usb-c | 12 × 4,6 / 8,4 × 2,6 |
| osfp | 22,6 × 11 | power-ac (IEC C14) | 24 × 16 |
| coax, bnc, antenna | Ø 9 / 9 / 8 | power-dc | 22 × 12 |
| generic | 10 × 10 | | |

Passos típicos entre portas vizinhas: RJ45 de 14 a 15 mm, SFP de 14,5 a 18 mm, SC de 13 a 16 mm. Portas em pilha 2×N, como RJ45 ímpar em cima e par embaixo, ficam com 17 a 19 mm entre as fileiras.

## 5. Slots e placas (chassis modulares)

```jsonc
"slots": [ { "id": "1", "face": "front", "x": 8.5, "y": 54, "w": 20.3, "h": 346, "accepts": ["pon"], "label": "1" } ],
"cards": {
  "GPFD": { "name": "H805GPFD", "role": "pon", "desc": "GPON 16 portas", "body": "light",
            "items": [ /* relativos ao slot */ ],
            "ports": [ { "id": "0", "type": "sfp", "x": 3.3, "y": 52, "role": "pon" } ] }
}
```

- `slots[].id` segue a numeração do fabricante (a mesma da CLI, como `display board`).
- `accepts` lista os `role` de placa aceitos, ou nomes de placa. O painel usa isso para oferecer só placas compatíveis.
- Quais placas estão instaladas é decidido no **dashboard** (`devices[].cards`), não no modelo. Assim, o mesmo modelo serve para qualquer configuração.
- A chave da porta de placa é `<slot>/<porta>`, por exemplo `3/7`. O nome exibido vem de `portLabel`, por exemplo `0/3/7`.

## 6. Dashboard

```jsonc
{
  "schema": "iso3d/dashboard@1",
  "title": "POP Centro",
  "subtitle": "Rua X, 100 · sala técnica",
  "models": { },                      // opcional; o build embute automaticamente os modelos da biblioteca
  "racks": [
    { "id": "r1", "name": "Rack 01", "units": 42, "pos": { "x": 0, "z": 0 },
      "width": 600, "depth": 1000, "frame": false }   // frame: true desenha as 4 colunas
  ],
  "devices": [
    { "id": "olt1", "model": "huawei-ma5600t", "name": "OLT-CENTRO-01",
      "rack": "r1", "u": 5,                              // U mais baixo ocupado (U1 = base do rack)
      "cards": { "1": "GPFD", "19": "X2CS" },
      "status": "up",
      "info": { "IP de gerência": "10.90.0.11" },        // pares livres exibidos no painel
      "ports": { "1/0": { "status": "up", "desc": "Centro · Cabo 03 FO 5", "metrics": { "ONUs online": "42/44" } } } },
    { "id": "onu-cliente", "model": "onu-xyz", "pos": { "x": 1500, "y": 0, "z": 200 } }   // fora de rack
  ],
  "links": [
    { "id": "F1", "a": "olt1:1/0", "b": "dio-a:1", "media": "fiber-sm", "status": "up",
      "label": "Cordão SC/APC 2 m", "color": "#f4c430", "info": { "Comprimento": "2 m" },
      "via": [[100, 900, -60]] }      // opcional: pontos de passagem no mundo (mm)
  ],
  "kpis": [ { "label": "ONUs online", "value": "3.412", "tone": "ok" } ],  // tone: ok | warn | crit | info
  "mode": "svg"                       // opcional: "svg" (padrão, desenho isométrico) ou "3d" (abre já no three.js)
}
```

Para posicionar racks lado a lado, some `width` mais um corredor de 100 a 200 mm ao `pos.x`. Para fileiras frente a frente, use outro `pos.z`. Como as frentes olham para −Z, a fileira de trás aparece pelas costas.

## 7. Estado e métricas (alimentação de dados)

O estado de cada porta fica em `devices[].ports["<chave>"]`:

| Campo     | Valores |
|-----------|---------|
| `status`  | `up`, `alarm`, `down`, `disabled`. Se faltar, vale o status do cabo, ou `free` quando não há cabo |
| `desc`    | texto livre (rota, cliente, circuito) |
| `metrics` | objeto `{ "rótulo": "valor com unidade" }`, mostrado na ordem do JSON |

O status do cabo fica em `links[].status`, e o do equipamento em `devices[].status`.

**Dados ao vivo:** a página expõe `window.IsoDash.update(patch)`, que mescla o patch e redesenha sem salvar no navegador:

```js
IsoDash.update({
  ports:   { "olt1:1/3": { status: "alarm", metrics: { "Rx médio ONUs": "-27.8 dBm" } } },
  links:   { "F12": { status: "down" } },
  devices: { "olt1": { status: "alarm" } }
});
```

Um coletor (SNMP, API do NMS, Zabbix, saída de CLI) só precisa produzir esse objeto, usando as referências `equipamento:porta`.

Outras funções disponíveis, úteis também para conferir a página com um navegador automatizado:

| Função | O que faz |
|---|---|
| `IsoDash.focus("rt1")` / `IsoDash.focus("rt1:xe-0/0/3")` | seleciona e enquadra um equipamento ou uma porta (zoom fechado) |
| `IsoDash.setView('iso'\|'front'\|'side'\|'rear'\|'top')` | gira a câmera com animação de ~0,6 s e reenquadra a cena inteira. Para combinar com `focus`, chame `focus` só depois que a animação terminar |
| `IsoDash.select(ref)` | seleciona sem mudar o enquadramento |
| `await IsoDash.mode('3d' \| 'svg')` | troca entre o 3D (three.js) e o desenho isométrico; retorna `false` se o 3D não puder abrir (sem internet ou sem WebGL) |
| `IsoDash.exportDrawio()` | retorna o XML de um arquivo `.drawio`: frente e traseira por rack, portas conectáveis (atributo `ref` = `equipamento:porta`) e cabos coloridos por tipo |
| `IsoDash.fit()` | enquadra tudo |
| `IsoDash.issues()` | lista os problemas de validação (`[nível, mensagem]`) |
| `IsoDash.data` | o JSON atual, com as edições do usuário |

## 8. Referências de porta

O formato é `<device.id>:<chave da porta>`.

- Porta fixa: `rt1:xe-0/0/0`
- Porta de placa: `olt1:3/7` (slot 3, porta 7)

## 9. Vocabulários

- **media** (`links[].media`): `fiber-sm` (amarelo, OS2), `fiber-mm` (aqua, OM3/OM4), `dac`, `aoc`, `cat5e`, `cat6`, `power`, `coax`, `e1`, `generic`
- **status**: `up`, `alarm`, `down`, `disabled` (e `free`, que é calculado)
- **body**: `light`, `dark`, `white`, `black`
- **category**: livre, mas prefira `olt`, `onu`, `switch`, `router`, `dio`, `patch-panel`, `server`, `firewall`, `radio`, `pdu`, `ups`, `dwdm`, `cpe`, `other`

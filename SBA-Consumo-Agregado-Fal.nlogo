;; Elementos globais do modelo
globals [
  renda                      ;; Renda média de todo o plano
  memória                           ;; memória dos agentes
  serie-real
]

;; No modelo existem dois tipos de agentes, os planejadores que consomem com base em uma
;; média e os imediatistas que consomem a renda atual
breed [planejadores planejador]   ;; Consomem via regra
breed [imediatistas imediatista]  ;; Consomem renda atual

;; Elementos pertencentes aos agentes, que nessa linguagem de programação
;; chamamos de "turtles".
turtles-own [
  talão-de-cheque  ;; Lista que recorda Credores e dívidas no formato [Credor, dívida]
  riqueza          ;; O capital acumulado do agente
  consumo          ;; O quanto o agente consome a cada passo de tempo
  ;; cálculo da pmgc
  pmgc
  renda-passada
  consumo-passado
]

;; Elementos pertencentes aos quadrinhos coloridos que formam o fundo do modelo.
;; Os "patches" são as fontes de renda dos agentes do modelo
patches-own [
  prenda ;; A renda disponibilizada para o agente que pousar nessa "fonte de renda"
]

;;  O que ocorre a cada passo de tempo no modelo
to go
  ask patches [set prenda item ticks serie-real]
  set renda item ticks serie-real
  adquirir-memória
  ask turtles [
    set riqueza riqueza + prenda ;;- Adquirir renda
    agente-paga   ;;- Caso houver dívidas, pagar a mais barata
    agente-pega-empréstimo ;; Agente pega empréstimo para poder consumir se não tiver renda suficiente
  ]
  agente-consome;;- Agente consome
  avaliar-pmgc
  tick          ;;- Adicionar uma passagem de tempo
end

;; Preparação para o modelo
to setup
  clear-all     ;; Limpar tudo
  reset-ticks
  ask patches [set pcolor white]
  set serie-real escolher-uma-das series-reais ;;dados trimestrais
  create-planejadores População-inicial * Porcentagem-planejador / 100 [ ;; Criar população inicial de planejadores
    setup-turtles
    setup-planejadores
  ]
  create-imediatistas População-inicial * (1 - Porcentagem-planejador / 100) [  ;; Criar população inicial de imediatistas
   setup-turtles
   setup-imediatistas
  ]
  set memória []
  repeat 1 [go]
  set serie-real remove first serie-real serie-real
  clear-all-plots
  reset-ticks   ;; Reiniciar contagem de tempo
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Regras dos Agentes ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Construção dos Agentes ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Construção idêntica a todos os agentes
to setup-turtles
  set shape "circle"                                          ;;- Formato base dos agentes
  move-to one-of patches with [not any? other turtles-here]   ;;- Mover para um lugar sem agentes
  set riqueza 100                                 ;;- Estabelecer riqueza inicial
  set talão-de-cheque []                                      ;;- Iniciar talão de cheque
end

;; Costrução específica para planejadores
to setup-planejadores
  set color blue ;; Colocar cor azul
  set consumo renda ;; Consumo inicial
end

;; Construção específica para imediatistas
to setup-imediatistas
  set color red ;; Colocar cor vermelho
  set consumo prenda ;; Consumo inicial
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Ações dos agentes ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Agente consome
to agente-consome
  ask planejadores [
    ;;set consumo (mean memória) * pmgc            ;;- Consumo ser a média observada de renda a partir da renda futura estimada
    set consumo (mean memória)
  ]
  ask imediatistas [
    set consumo prenda                         ;;- Consumir renda atual
  ]
  ask turtles [
    if riqueza <= 0 or riqueza < consumo [
      set consumo 0
    ]
    set riqueza (riqueza - consumo)  ;;- Riqueza é diminuida com consumo
  ]
end

to adquirir-memória
  set memória insert-item 0 memória renda
  if (length memória > lembrança) [
    set memória remove-item lembrança memória
  ]
end

to avaliar-pmgc
  ask turtles [
;    ifelse (prenda = renda-passada)[
;      ifelse (consumo-passado = consumo) [
;        let variação-renda 1
;        let variação-consumo 1
;        set pmgc 1
;      ][
;        let variação-renda 1
;        let variação-consumo (consumo - consumo-passado)
;        set pmgc variação-consumo / variação-renda
;      ]
;    ][
      let variação-renda (prenda - renda-passada)
      let variação-consumo (consumo - consumo-passado)
      set pmgc variação-consumo / variação-renda
;    ]
    set renda-passada prenda
    set consumo-passado consumo
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Agente efetua trocas ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Agente pega empréstimo
;; Possibilidade de extensões são:
;; 1. O Mututante registrar para quem emprestou o dinheiro
;; 2. Marcador no empréstimo que mostra quando foi feito,
;;    consequentemente marcar quanto tempo passou
;; 3. Juros
;; 4. Decisões baseadas em juros
to agente-pega-empréstimo
  if riqueza < consumo [                                                 ;;- Caso a renda do agente é menor que o quanto quer consumir
    let vontade-restrita (abs (riqueza - consumo))                       ;;- Verifica-se o quanto a mais o agente quer e registra em "vontade-restrita"
    let mutuante one-of turtles with [riqueza > vontade-restrita]       ;;- Escolhe um agente aleatório que tem riqueza suficiente para emprestar
    if not (mutuante = nobody) [                                        ;;- Se tal agente existir:
      let empréstimo list mutuante vontade-restrita                     ;;- Registra em "empréstimo" quem vai emprestar e quanto
      set talão-de-cheque insert-item 0 talão-de-cheque empréstimo      ;;- Coloca registro ("empréstimo") no "talão-de-cheque" de quem pegou emprestado
      set riqueza riqueza + vontade-restrita                            ;;- Agente que precisa do empréstimo recebe o dinheiro
      ask mutuante [set riqueza riqueza - vontade-restrita]             ;;- Mutuante tem dinheiro retirado da conta
    ]
  ]
end

;; Agente paga dívida mais barata
to agente-paga
  if riqueza > 0 [
    if not empty? talão-de-cheque [                                        ;;- Se o talão-de-cheque não estiver vazia, pagar a menor dívida se tiver como
      let pagamentos []                                                    ;;- Criar variável para guardar lista de valores de dívidas
      foreach talão-de-cheque [i -> set pagamentos fput last i pagamentos] ;;- Alimentar a lista com os valores das dívidas
      let pagamento min pagamentos                                         ;;- Estabelecer qual valor é o menor para poder ser pago
      ifelse pagamento <= riqueza [                                            ;;- Pagar dívida se for igual ou menor que a riqueza
        foreach talão-de-cheque [
          i -> if last i = pagamento [                                     ;;- Procura a dívida de valor exato a ser paga
            if not (first i = nobody) [                                    ;;- Se dívida existir faça o seguinte:
              ask first i [set riqueza riqueza + pagamento]                ;;- 1. Aumente a riqueza do mutuante pelo valor da dívida
              set riqueza riqueza - pagamento                              ;;- 2. Diminua a riqueza do agente devedor pelo valor da dívida
              set talão-de-cheque remove i talão-de-cheque                 ;;- 3. Retire registro de dívida do talão-de-cheque
              stop                                                         ;;- Encerra procura por mais dívidas
            ]
          ]
        ]
      ][
        ;; Utilizar toda a riqueza pra pagar dívida
        let all-in riqueza                                                 ;;- all-in seria o valor a pagar igual à riqueza do agente
        foreach talão-de-cheque [
          i -> if last i = pagamento [                                     ;;- Procura a dívida de valor exato a ser paga
            if not (first i = nobody) [                                    ;;- Se dívida existir faça o seguinte:
              ask first i [set riqueza riqueza + all-in]                   ;;- 1. Aumente a riqueza do mutuante pelo valor da dívida
              set riqueza 0                                                ;;- 2. Agente fica sem riqueza
              set i replace-item 1 i (pagamento - all-in)                  ;;- 3. Recalcula dívida
              stop                                                         ;;- Encerra procura por mais dívidas
            ]
          ]
        ]
      ]
      foreach talão-de-cheque [i ->
        if item 0 i = nobody [set talão-de-cheque remove i talão-de-cheque] ;;- Deletar do talão de cheque se mutuante morreu
      ]
    ]
  ]
end

to-report escolher-uma-das [serie]
  if serie = "A0" [
    report [
170919.996543207
176708.745854592
189844.258417871
184112.941748036
176732.253490737
185109.483745549
193244.899551921
190996.037177227
178512.963194271
187903.995178026
193932.077830581
188256.127630064
179883.349009013
187150.990293636
192737.004150926
192336.825167043
187799.484444951
194596.620599114
201534.656469663
201179.533307516
194325.686124496
199123.045788155
202464.125736875
200109.656930469
195252.462490979
203699.296663333
210916.413827037
210460.585453175
200459.901102397
205290.681904669
212237.131727644
211699.592061292
208233.90117085
218240.944898475
226157.354572227
224844.801622416
216947.076811461
228007.165979781
230940.521218273
229680.20469392
226230.452129781
233213.247665819
241316.189338512
240693.857710983
237982.424442897
248458.997191351
255482.05738865
256675.292082065
252635.964946943
264201.667207618
273316.777644987
259314.934439036
246506.878386696
258381.342930824
270139.060069406
273121.704484446
269207.926734265
280389.588644803
288797.993934375
288660.499253212
283193.598555691
293569.312777341
299013.784467651
296073.286888741
288028.251268607
296465.268051813
306445.51275152
303424.251066248
295865.938833273
308388.864770547
314900.334666094
311096.643565617
306129.944757442
307045.583460594
312888.230466802
310387.947625067
301174.166906798
298635.19880446
299553.285344549
293247.403273792
285692.248945051
288975.832794303
292084.570329819
286436.221780283
286093.835449798
290657.814280706
296042.210004396
292663.343798111
289580.582650391
293289.238586796
299801.422472357
295810.866902352
290915.91644333
    ]
  ]
  if serie = "A1" [
    report [
177986.564026725
177140.840141802
184255.625417395
182279.348232551
183685.744370481
185499.857431406
187810.987286679
189192.050761189
185265.612458961
188246.274474672
188751.606777615
186496.478334855
186359.380702982
187465.588189893
187819.087550194
190618.986516702
193999.762342449
194886.130990286
196867.185480148
199486.436041521
200302.215351627
199427.371433153
197930.753575026
198432.649021748
201120.833905401
203987.901819562
206432.396290744
208852.795365764
206260.927971915
205580.107857809
207677.592923912
210216.948764529
214038.367215304
218453.28927734
221540.30810353
223474.800186772
222801.320151147
228154.628954313
226223.000065016
228336.06731005
232253.95050122
233298.1661932
236490.33072482
239288.921800719
244234.598534409
248551.753886797
250479.884703645
255144.977317366
259207.609889264
264258.661990552
268189.935182297
257625.531446356
253376.127210717
258447.276350003
264825.60644251
271382.314452512
276271.77129632
280419.261240141
283410.682672022
287002.73274145
290118.355719799
293695.524525187
293637.187612494
294582.936420083
294563.092867088
296703.507949374
301274.574551681
302085.48235923
301844.26568878
308819.3576055
309931.982484483
309958.22947426
311548.038515471
307575.072632513
308162.888562007
309488.339687046
306041.199497734
299253.105877486
295004.362383171
292559.884669625
290217.875306531
289555.037051583
287639.205330784
285929.891968645
290475.399191038
291179.591418175
291546.502714007
292320.102858225
293987.490489593
293696.033687869
295235.392569796
295590.54557683
295334.74185944
    ]
  ]
  if serie = "A2" [
    report [
96.839683619772
100.119467514028
107.561773309359
104.314529544694
100.132786447406
104.879149330001
109.488505220113
108.214346986587
101.14169920072
106.462460870289
109.877846013711
106.661971728804
101.918131048489
106.035824103128
109.2007423431
108.974009327805
106.403247281882
110.254362002232
114.185307545381
113.984102213273
110.100856213943
112.818939536169
114.71192532909
113.377932707301
110.625948256604
115.411747258377
119.500814406253
119.242551614289
113.576373705926
116.313392744013
120.249105456057
119.944546760319
117.980959022535
123.65074002038
128.136011631165
127.392346671157
122.917661511568
129.184075960013
130.846053487424
130.131984590001
128.177427173466
132.133732603887
136.724689331263
136.372089289516
134.835848093939
140.771654382838
144.750772925455
145.426834665049
143.138236667663
149.691120884936
154.855551195996
146.92240063678
139.665624829513
146.393447277818
153.055123095856
154.745026836462
152.527562486176
158.862857499396
163.626883502539
163.548981901249
160.451550678245
166.330212642176
169.414936060323
167.748911832699
163.190763459658
167.971000134738
173.62559736569
171.913813890078
167.631432775264
174.726659842232
178.415922054597
176.26083049008
173.446803161822
173.965584838142
177.275906035347
175.859298240762
170.638963418946
169.200437367438
169.720605936803
166.147825472106
161.867233559568
163.727643268974
165.488988725824
162.288752957197
162.094764046651
164.68061868608
167.731304322117
165.81690962853
164.070281847941
166.171528482622
169.861195226747
167.600230174781
164.826853955654
    ]
  ]
  if serie = "A3" [
    report [
100.843452477845
100.364283070508
104.395371117815
103.275653933191
104.072488474472
105.10032686918
106.409764550641
107.192246136384
104.967608582965
106.656389137708
106.942699817146
105.664991360935
105.587314719441
106.214068669926
106.41435398998
108.000717994004
109.916194637908
110.418392515061
111.540816420466
113.024828828693
113.487032268267
112.991364060947
112.143411786129
112.427775214948
113.950844363727
115.575264884082
116.960264158521
118.33161148709
116.863113807
116.477375416025
117.66576644286
119.104512178741
121.269647687963
123.771049889814
125.520089981685
126.61613260452
126.234552947995
129.267625387161
128.173204989937
129.370424552393
131.590214959399
132.181845659652
133.990459101943
135.576082082591
138.378198744553
140.82420838016
141.916646842935
144.559790430031
146.861592798875
149.723412933022
151.950789833391
145.965220349943
143.557597075461
146.430803769641
150.044631763282
153.759524942064
156.529788594083
158.879669369293
160.574545983473
162.60972618067
164.374972784952
166.401721570199
166.368669099553
166.904510529245
166.893267588496
168.105981861698
170.695852283679
171.155295632123
171.018627328106
174.970568049467
175.600957959643
175.615828953309
176.516581397028
174.265582292657
174.598626464142
175.349599259591
173.396521959817
169.550530549444
167.143281637132
165.758291857217
164.431358494571
164.055808247681
162.970338194655
162.001877110263
164.577266123898
164.976246663698
165.184130905001
165.62243651423
166.567143359297
166.402010051091
167.274178493157
167.475400734752
167.330467716019
    ]
  ]
  if serie = "B0" [
    report [
1088.17609454704
1120.9613435269
1199.28703838511
1158.06913829051
1107.09236175795
1155.37614259334
1202.20123574507
1184.43672834604
1103.36003491749
1157.24410828242
1190.050456221
1151.38306299126
1097.20056579199
1139.2497756381
1170.74589017211
1164.40274795939
1130.55588288025
1161.5927525184
1190.93859938006
1176.94294012064
1127.27183338435
1148.49754780002
1163.69227139626
1147.71994501221
1118.07337223729
1164.3064008667
1202.54550747761
1195.72949633261
1133.3650277427
1153.31794683785
1183.89496040413
1172.73139780711
1146.782282552
1196.83141146516
1236.30275669208
1225.39258303924
1177.88062943022
1231.76360599736
1241.35792360754
1230.27341559696
1211.27467684003
1253.02365645687
1303.63902340906
1306.41202453336
1293.28071293515
1344.63355754022
1371.68312389932
1365.21963686652
1332.37812159121
1385.30099714622
1428.46612580423
1353.66000767884
1287.19695476965
1350.91786014587
1414.60528758606
1431.88544199234
1411.440907631
1467.85821084767
1508.12728514042
1503.4391047755
1472.05867623208
1524.68048952707
1551.78417961296
1533.42588087396
1484.86134517721
1516.15349096964
1551.68805005825
1521.23151209757
1471.51017005575
1526.49025640115
1555.23025865524
1535.08046479049
1509.52008060217
1511.89000570137
1537.48354045729
1521.55935246747
1472.86064721472
1457.29561567404
1458.90382378954
1425.49386219256
1386.08806814263
1399.16176683791
1411.34152836237
1381.46951797016
1377.69698338294
1398.10795653679
1422.75624142627
1405.27804954913
1388.90966949499
1404.51509869266
1432.95377796481
1410.83733741517
1384.34402299499
    ]
  ]
  if serie = "B1" [
    report [
1133.16597262795
1123.70235665773
1163.98244094498
1146.53584767936
1150.65066245557
1157.81269221905
1168.39617255659
1173.24954456898
1145.09707852012
1159.3521033735
1158.26086262211
1140.62096764374
1136.70119593844
1141.16483674553
1140.87289990809
1154.00299199342
1167.88165442444
1163.3209077717
1163.35688484882
1167.03796200786
1161.94132661248
1150.2528305983
1137.63604968831
1138.10154151132
1151.6774033115
1165.95601299706
1176.97976299202
1186.59485467375
1166.16301348824
1154.94393464665
1158.46107441272
1164.5181446358
1178.74854156183
1197.99590616065
1211.063394975
1217.92614580842
1209.66533900609
1232.56024554367
1216.00017247539
1223.07359403424
1243.5254679012
1253.47991237176
1277.56875590024
1298.78646572466
1327.25723950174
1345.13554686962
1344.82645958017
1357.08010870856
1367.03635382609
1385.59984056559
1401.67113409758
1344.8410891966
1323.06644541308
1351.26258563007
1386.78095298588
1422.76640376221
1448.47621822151
1468.01354886473
1479.99429502642
1494.80490991053
1508.05401269524
1525.33598239065
1523.88139260652
1525.7070420546
1518.55017133819
1517.37187400233
1525.50498429809
1514.51953328451
1501.2438014514
1528.62114760079
1530.69255323587
1529.46305531781
1536.23658274903
1514.49720616369
1514.26395373517
1517.14936528168
1496.66235917934
1460.3109108302
1436.7493643756
1422.15179150603
1408.04497010159
1401.96615516388
1389.86169385833
1379.02751117204
1398.79658917946
1400.61778332139
1401.15021569456
1403.62991366621
1410.04643513867
1406.46317515221
1411.12963268485
1409.78653912798
1405.37131716382
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
977
465
1206
695
-1
-1
2.242424242424242
1
10
1
1
1
0
1
1
1
-49
49
-49
49
1
1
1
ticks
30.0

BUTTON
5
151
243
184
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
5
185
119
221
NIL
go
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

MONITOR
43
227
208
272
Consumo Per Capita Atual
mean [consumo] of turtles
2
1
11

MONITOR
43
272
208
317
PIB per capita Atual
mean [prenda] of patches
4
1
11

SLIDER
5
71
242
104
Porcentagem-planejador
Porcentagem-planejador
0
100
38.3
0.1
1
%
HORIZONTAL

PLOT
22
325
222
475
pmgc
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"pmgc" 1.0 0 -16777216 true "" "plot mean [pmgc] of turtles"
"pmgc planejadores" 1.0 0 -14070903 true "" "plot mean [pmgc] of planejadores"
"pmgc imediatistas" 1.0 0 -2674135 true "" "plot mean [pmgc] of imediatistas"

PLOT
978
312
1178
462
Poupança Corrente
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Poupança Corrente" 1.0 0 -16777216 true "" "plot (sum [prenda] of turtles) - (sum [consumo] of turtles)"
"Poupança Corrente Imediatistas" 1.0 0 -2674135 true "" "plot (sum [prenda] of imediatistas) - (sum [consumo] of imediatistas)"
"Poupança Corrente Planejadores" 1.0 0 -14070903 true "" "plot (sum [prenda] of planejadores) - (sum [consumo] of planejadores)"

MONITOR
977
10
1170
55
Cosumo corrente Planejadores
sum [consumo] of planejadores / count turtles
17
1
11

MONITOR
977
55
1170
100
Consumo corrente Imediatistas
sum [consumo] of imediatistas / count turtles
17
1
11

INPUTBOX
119
10
242
70
lembrança
23.0
1
0
Number

MONITOR
246
372
974
417
Memória
memória
17
1
11

PLOT
246
10
974
373
Dados Principais
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Consumo Planejador" 1.0 0 -14454117 true "" "plot (mean [consumo] of planejadores * (Porcentagem-planejador / 100))"
"Consumo Agregado" 1.0 0 -16448764 true "" "plot mean [consumo] of turtles "
"Consumo Imediatista" 1.0 0 -2674135 true "" "plot mean [consumo] of imediatistas *( 1 - (Porcentagem-planejador / 100))"
"PIB (per capita)" 1.0 0 -1184463 true "" "plot mean [prenda] of patches"

BUTTON
120
185
243
221
go definido
repeat length serie-real [go]
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

MONITOR
22
475
222
520
pmgc atual
mean [pmgc] of turtles
17
1
11

PLOT
246
419
974
728
3º pressuposto Campbell Mankiw
NIL
NIL
0.0
10.0
0.0
0.8
true
true
"" ""
PENS
"Ln Propensão média a consumir" 1.0 0 -16777216 true "" "plot ln (mean [consumo] of turtles / mean [prenda] of patches)"
"Ln do PIB per capita" 1.0 0 -7500403 true "" "plot ln (mean [prenda] of turtles)"

MONITOR
977
264
1218
309
Propensão Média a Consumir atual
mean [consumo] of turtles / mean [prenda] of patches
17
1
11

PLOT
977
114
1218
264
Propensão Média a Consumir
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [consumo] of turtles / mean [prenda] of patches"

CHOOSER
5
105
242
150
series-reais
series-reais
"A0" "A1" "A2" "A3" "B0" "B1"
1

INPUTBOX
5
10
118
70
População-inicial
1000.0
1
0
Number

@#$#@#$#@
##Descrição do Modelo 


## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment 1" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="800"/>
    <metric>count</metric>
    <metric>count</metric>
    <enumeratedValueSet variable="cor-min">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lacuna">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visão">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor-max">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pmgc">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dsv-padrão">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raios">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%rendas-visíveis">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bater-as-botas?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="idade-máxima">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplicador">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incerteza">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="1790"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="focos-móveis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Porcentagem-planejador">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="concentração-exponencial-de-renda?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment teste" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="cor-min">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lacuna">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visão">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor-max">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pmgc">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dsv-padrão">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raios">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%rendas-visíveis">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bater-as-botas?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="idade-máxima">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplicador">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incerteza">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="1790"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="focos-móveis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Porcentagem-planejador">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="concentração-exponencial-de-renda?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="pc-bianca" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>sum [consumo] of turtles</metric>
    <enumeratedValueSet variable="cor-min">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lacuna">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visão">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor-max">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'1">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="pmgc" first="0.7" step="0.05" last="0.95"/>
    <enumeratedValueSet variable="dsv-padrão">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raios">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%rendas-visíveis">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bater-as-botas?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="semente" first="1" step="1" last="50"/>
    <enumeratedValueSet variable="idade-máxima">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incerteza">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplicador">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="1790"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="focos-móveis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Porcentagem-planejador">
      <value value="10"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="concentração-exponencial-de-renda?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="novo" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>sum [consumo] of turtles</metric>
    <enumeratedValueSet variable="cor-min">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lacuna">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visão">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor-max">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pmgc">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dsv-padrão">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raios">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%rendas-visíveis">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bater-as-botas?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="semente">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="idade-máxima">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incerteza">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplicador">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="1790"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="focos-móveis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Porcentagem-planejador">
      <value value="10"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="concentração-exponencial-de-renda?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="novo-25" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>sum [consumo] of turtles</metric>
    <enumeratedValueSet variable="cor-min">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lacuna">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visão">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor-max">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pmgc">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dsv-padrão">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raios">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%rendas-visíveis">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bater-as-botas?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="semente">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="idade-máxima">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incerteza">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplicador">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="1790"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="focos-móveis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Porcentagem-planejador">
      <value value="10"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="concentração-exponencial-de-renda?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="um-a-um-errata" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>sum [consumo] of turtles</metric>
    <enumeratedValueSet variable="cor-min">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lacuna">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visão">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor-max">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'1">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="pmgc" first="0.1" step="0.1" last="1"/>
    <enumeratedValueSet variable="dsv-padrão">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raios">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%rendas-visíveis">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bater-as-botas?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="semente">
      <value value="34"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="idade-máxima">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incerteza">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplicador">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="1790"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="focos-móveis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Porcentagem-planejador">
      <value value="10"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="concentração-exponencial-de-renda?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lembrança">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="cor-min">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lacuna">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visão">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor-max">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pmgc">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dsv-padrão">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raios">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%rendas-visíveis">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bater-as-botas?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="semente">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="idade-máxima">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incerteza">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplicador">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="1790"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="focos-móveis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Porcentagem-planejador">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="concentração-exponencial-de-renda?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="real-100-bi" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="113"/>
    <metric>sum [consumo] of turtles</metric>
    <metric>sum [consumo] of planejadores</metric>
    <metric>sum [consumo] of imediatistas</metric>
    <enumeratedValueSet variable="cor-min">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lacuna">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visão">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor-max">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'1">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="pmgc" first="0.1" step="0.1" last="1"/>
    <enumeratedValueSet variable="dsv-padrão">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raios">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%rendas-visíveis">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y'1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bater-as-botas?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="semente">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="idade-máxima">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incerteza">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplicador">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x'">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="focos-móveis?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Porcentagem-planejador" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="concentração-exponencial-de-renda?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="lembrança" first="1" step="1" last="100"/>
  </experiment>
  <experiment name="real-100-less-newmemory" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="113"/>
    <metric>sum [consumo] of turtles</metric>
    <metric>sum [consumo] of planejadores</metric>
    <metric>sum [consumo] of imediatistas</metric>
    <steppedValueSet variable="pmgc" first="0.7" step="0.1" last="1"/>
    <enumeratedValueSet variable="semente">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="2000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Porcentagem-planejador" first="60" step="10" last="100"/>
    <steppedValueSet variable="lembrança" first="88" step="1" last="98"/>
  </experiment>
  <experiment name="real-100-less-newmemory" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="113"/>
    <metric>sum [consumo] of turtles</metric>
    <metric>sum [consumo] of planejadores</metric>
    <metric>sum [consumo] of imediatistas</metric>
    <steppedValueSet variable="riqueza-inicial" first="0" step="20" last="100"/>
    <steppedValueSet variable="pmgc" first="0.1" step="0.2" last="0.9"/>
    <enumeratedValueSet variable="semente">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="População-inicial">
      <value value="2000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Porcentagem-planejador" first="0" step="20" last="100"/>
    <steppedValueSet variable="lembrança" first="5" step="5" last="100"/>
  </experiment>
  <experiment name="so-memoria-porcentagem" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="113"/>
    <metric>sum [consumo] of turtles</metric>
    <enumeratedValueSet variable="População-inicial">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Porcentagem-planejador" first="50" step="0.2" last="100"/>
    <steppedValueSet variable="lembrança" first="72" step="1" last="113"/>
  </experiment>
  <experiment name="serie-trimestral" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="92"/>
    <metric>sum [consumo] of turtles</metric>
    <enumeratedValueSet variable="População-inicial">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Porcentagem-planejador" first="50" step="0.2" last="100"/>
    <steppedValueSet variable="lembrança" first="72" step="1" last="113"/>
  </experiment>
  <experiment name="serie-trimestral-2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="92"/>
    <metric>sum [consumo] of turtles</metric>
    <enumeratedValueSet variable="População-inicial">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Porcentagem-planejador" first="0" step="2" last="100"/>
    <steppedValueSet variable="lembrança" first="0" step="1" last="92"/>
  </experiment>
  <experiment name="A0-geral" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="92"/>
    <metric>sum [consumo] of turtles</metric>
    <enumeratedValueSet variable="População-inicial">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Porcentagem-planejador" first="0" step="2" last="100"/>
    <steppedValueSet variable="lembrança" first="0" step="1" last="92"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

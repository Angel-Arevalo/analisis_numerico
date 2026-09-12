### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ a12c089d-621c-44cf-ab6a-86b1b1ff7d13
using Random, Statistics, Printf

# ╔═╡ 570241bb-942a-43df-8572-6af37d737bc7
md"
# ¿El error de redondeo en Float32 crece siempre igual sin importar cómo se vayan sumando los números?

Cuando estábamos viendo cómo se representan los números en Float32 me quedé pensando en algo parecido a lo que vimos: $0.1$ no se puede representar de forma exacta en binario.

$0.1 = (1.10011001100110011001101\ldots)_2 \cdot 2^{-4}$

y su número de máquina en Float32 (redondeando a 23 bits de mantisa) queda

$$0 \quad 01111011 \quad 10011001100110011001101$$

que corresponde al valor decimal $0.10000000149011612\ldots$, es decir, un poquito más grande que $0.1$. La diferencia entre lo que quería guardar y lo que realmente quedó guardado es

$$e = 0.1 - 0.10000000149011612\ldots \approx -1.49 \times 10^{-9}$$

Eso ya lo tenía claro: cada vez que guardo $0.1$ en la máquina, cometo ese error de representación una sola vez.

La pregunta concreta que quiero responder es: **¿el error acumulado al sumar $n$ veces el mismo valor de Float32 crece de la misma forma que el error acumulado al sumar $n$ valores de la misma magnitud pero con signo aleatorio (a veces sumando, a veces restando)?**
"

# ╔═╡ 6e40e6a9-cbdb-47a5-a926-35da7b031533
md"
## 2. ¿Por qué es interesante?

Escogí esta pregunta porque en las dos situaciones se hacen exactamente el mismo número de sumas, con el mismo formato (Float32) y con números de la misma magnitud. Lo único que cambia es el signo con el que se van acumulando. Si el error solamente dependiera de cuántas sumas hago y del épsilon de máquina, no debería importar el signo: en los dos casos estoy haciendo $n$ operaciones de suma, y según lo que entendía yo, cada suma tiene la misma probabilidad de necesitar redondeo.

Me parece que esto se conecta directamente con lo que vimos en clase sobre representación de punto flotante: como la mantisa tiene una cantidad fija de bits, el resultado exacto de una suma casi nunca cae justo en un número de máquina representable, entonces hay que redondearlo. La pregunta es si ese redondeo se comporta siempre igual sin importar el signo de lo que se está sumando.
"

# ╔═╡ e8793e6b-8ac2-46f9-a2fa-fb2366a4dc77
md"
## 3. Predicción inicial

En clase solo hemos visto representación de números de máquina y el épsilon de máquina, no hemos visto nada sobre qué tan rápido crecen los errores en general, así que mi predicción parte solamente de esas dos ideas.

El épsilon de máquina de Float32 es

$$\epsilon_{32} = 2^{-23} \approx 1.1920929 \times 10^{-7}$$

y mi razonamiento fue el siguiente: si cada suma comete un error de redondeo del tamaño de más o menos $\epsilon_{32}$, entonces después de $n$ sumas el error total debería ser aproximadamente $n$ veces ese valor, sin importar si voy sumando siempre lo mismo o si el signo cambia aleatoriamente, porque en los dos casos hago la misma cantidad de sumas con el mismo formato.

Es decir, esperaba que las dos series de errores se vieran prácticamente iguales, o que en el peor de los casos la versión con signo aleatorio tuviera un error apenas un poco menor porque de vez en cuando un error se cancela con el siguiente, pero no esperaba una diferencia grande entre los dos casos.
"

# ╔═╡ 1c7b4d54-ac2d-495a-9fa0-ee7e3fbb74c3
md"
## 4. Investigación / experimento

Para poner a prueba esto diseñé el siguiente experimento en Julia:

- Formato usado: **Float32** en todas las sumas.
- Valor base: $c = 0.1$ (justo el que analicé arriba, porque no es representable exactamente y entonces sí genera redondeo real en cada suma).
- **Caso 1 (signo siempre igual):** sumar $c$ un total de $n$ veces, siempre sumando (nunca restando).
- **Caso 2 (signo aleatorio):** sumar $c$ un total de $n$ veces, pero en cada paso se decide al azar si se suma $+c$ o se suma $-c$.
- Como referencia de lo que sería el valor 'verdadero' (sin el redondeo que se va acumulando al sumar en Float32), hice el mismo cálculo pero con `BigFloat`, que tiene muchísimos más bits de precisión, así que el error que se acumula ahí es completamente despreciable para los tamaños de $n$ que uso.
- La cantidad que mido es el **error absoluto**: $\lvert \text{resultado en Float32} - \text{resultado en BigFloat} \rvert$.
- Usé $n \in \{10,\ 100,\ 1\,000,\ 10\,000,\ 100\,000,\ 1\,000\,000\}$.
- Para el caso aleatorio, como el resultado depende de qué signos salieron, repetí el experimento con 30 semillas distintas y promedié el error, para no quedarme con una sola corrida que podría ser casualidad.

"

# ╔═╡ 2b19a97e-38ea-4f3d-b757-f391b988e819
begin
    c = 0.1f0
    eps32 = eps(Float32)
    (c, eps32)
end

# ╔═╡ 1a7c5cdb-d277-4380-a779-ef19e981d910
function suma_constante(n::Integer)::Float32
    acc = 0.0f0
    for _ in 1:n
        acc += c
    end
    return acc
end

# ╔═╡ e6b56453-7fb1-4290-88a7-f1664d1f1085
function suma_aleatoria(n::Integer, rng::AbstractRNG):Float32
    acc = 0.0f0
    c_big = BigFloat(Float64(c))
    exacto = BigFloat(0)
    for _ in 1:n
        signo = rand(rng, (1, -1))
        acc += Float32(signo) * c
        exacto += signo * c_big
    end
    return acc, exacto
end

# ╔═╡ 601084a6-fb55-410e-903f-5bef74eae216
ns = [10, 100, 1_000, 10_000, 100_000, 1_000_000]

# ╔═╡ eafbb3ef-db4c-4895-82e3-53bb89dda614
begin
    errores_constante = Float64[]
    c_big = BigFloat(Float64(c))
    for n in ns
        resultado = suma_constante(n)
        exacto = c_big * n
        error_abs = abs(Float64(resultado) - Float64(exacto))
        push!(errores_constante, error_abs)
        println("n = ", n, "  ->  resultado = ", resultado, "   error = ", error_abs)
    end
end

# ╔═╡ 23c1b2b4-ed53-4fd0-add0-867f22a611dd
begin
    errores_aleatoria = Float64[]
    for n in ns
        errores_trial = Float64[]
        for seed in 1:30
            rng = MersenneTwister(seed)
            resultado, exacto = suma_aleatoria(n, rng)
            push!(errores_trial, abs(Float64(resultado) - Float64(exacto)))
        end
        error_promedio = mean(errores_trial)
        push!(errores_aleatoria, error_promedio)
        println("n = ", n, "  ->  error promedio (30 corridas) = ", error_promedio)
    end
end

# ╔═╡ f847c3dd-8343-42fa-a377-1628fb4e58e6
function pendiente_log(ns, errores)
    x = log10.(Float64.(ns))
    y = log10.(errores)
    xm, ym = mean(x), mean(y)
    return sum((x .- xm) .* (y .- ym)) / sum((x .- xm) .^ 2)
end

# ╔═╡ b6b5704a-f970-42c4-a8ec-746bda648209
(pendiente_constante = pendiente_log(ns, errores_constante), pendiente_aleatoria = pendiente_log(ns, errores_aleatoria))

# ╔═╡ 1c4b3be9-10d3-413c-826a-90ce91917dde
md"
## 5. Resultados y explicación

Estos fueron los resultados que obtuve al correr el código de arriba (los valores del caso 1 son exactos porque no dependen de ningún número aleatorio; los del caso 2 son el promedio de las 30 corridas):

| $n$ | error caso 1 (mismo signo) | error caso 2 (signo aleatorio, promedio) |
|---|---|---|
| 10 | $1.04\times10^{-7}$ | $1.09\times10^{-8}$ |
| 100 | $1.76\times10^{-6}$ | $5.76\times10^{-8}$ |
| 1 000 | $9.55\times10^{-4}$ | $8.75\times10^{-7}$ |
| 10 000 | $9.71\times10^{-2}$ | $6.56\times10^{-6}$ |
| 100 000 | $1.44$ | $7.83\times10^{-5}$ |
| 1 000 000 | $9.58\times10^{2}$ | $3.96\times10^{-4}$ |

Lo primero que me llamó la atención es que en el caso 1, con $n = 1\,000\,000$, el resultado que da la máquina es $100958.34375$ cuando debería ser $100000.0015\ldots$, es decir, un error absoluto de casi mil y un error relativo de casi el $1\%$. Eso claramente NO es del tamaño de $\epsilon_{32} \approx 1.19\times 10^{-7}$ como yo pensaba, ni siquiera es del tamaño de $n \cdot \epsilon_{32} \approx 0.119$. El error real es miles de veces más grande que mi predicción.

En cambio, en el caso 2, con el mismo $n = 1\,000\,000$, el error promedio es $3.96\times10^{-4}$: muchísimo más chico que en el caso 1, a pesar de que en los dos casos se hicieron exactamente la misma cantidad de sumas en Float32.

Para entender qué tan rápido crece cada error, ajusté una recta a los puntos de la tabla en escala log-log (es decir, a $\log_{10}(n)$ contra $\log_{10}(\text{error})$, que es lo que hace la función `pendiente_log`). La pendiente de esa recta me dice a qué potencia de $n$ es proporcional el error: si el error fuera proporcional a $n$, la pendiente debería salir $1$; si fuera proporcional a $n^2$, debería salir $2$. Obtuve:

- Caso 1 (mismo signo): pendiente $\approx 1.99$, es decir, el error crece casi como $n^2$.
- Caso 2 (signo aleatorio): pendiente $\approx 1.00$, es decir, el error crece aproximadamente proporcional a $n$.

Esto contradice directamente mi predicción inicial, que era que ambos deberían crecer más o menos igual.

**¿Por qué pasa esto?** Pensándolo con lo que sabemos de representación, creo que la explicación es la siguiente. El épsilon de máquina $\epsilon_{32}$ no es un error absoluto fijo: es una cota **relativa**. Cuando la máquina redondea un número $x$ al número de máquina más cercano, el error cometido es aproximadamente $\epsilon_{32} \cdot |x|$, no una cantidad constante. Como Float32 solo tiene 23 bits de mantisa sin importar qué tan grande sea el número, el 'hueco' entre dos números de máquina consecutivos crece conforme crece la magnitud del número representado.

En el caso 1, el acumulador va creciendo de forma sostenida: después de $k$ sumas, el acumulador vale aproximadamente $k \cdot c$. Entonces el redondeo que se comete en el paso $k$ no es del tamaño fijo $\epsilon_{32} \cdot c$, sino del tamaño $\epsilon_{32} \cdot (k \cdot c)$, que crece con $k$. Y como siempre estoy sumando en la misma dirección, estos errores de redondeo tienden a acumularse en la misma dirección en vez de cancelarse. Si sumo esos errores crecientes desde $k=1$ hasta $k=n$:

$$\text{error total} \approx \epsilon_{32} \cdot c \cdot (1 + 2 + \cdots + n) = \epsilon_{32} \cdot c \cdot \frac{n(n+1)}{2}$$

y esa suma $1+2+\cdots+n$ crece proporcional a $n^2$, no a $n$. Ahí está mi error de predicción: yo estaba pensando el épsilon de máquina como si fuera un error absoluto fijo del tamaño de una sola suma, sin darme cuenta de que ese error depende de qué tan grande sea el acumulador en ese momento, y el acumulador mismo va creciendo.

En el caso 2, el acumulador no crece de forma sostenida: como a veces se suma $c$ y a veces se resta $c$, el acumulador se queda dando vueltas cerca de valores mucho más chicos que $n \cdot c$. Como el acumulador es más chico, cada redondeo individual también es más chico, porque de nuevo el error de redondeo depende del tamaño del número, no es fijo. Y además, como el signo de lo que se suma cambia aleatoriamente, el redondeo de un paso no siempre 'apunta' en la misma dirección que el del paso anterior, entonces hay cancelación parcial entre los errores en lugar de que se acumulen todos igual. Por eso el error crece mucho más lento, cercano a $n$.
"

# ╔═╡ a535cbe1-ff5b-4fe1-9704-b14a3024dec5
md"
## 6. Conclusión

El orden y el signo con el que se suman los números sí importa, y no de forma chiquita: en mi experimento, sumar siempre en la misma dirección hizo que el error creciera casi con el cuadrado de $n$, mientras que alternar signos aleatoriamente hizo que el error creciera solamente cerca de proporcional a $n$. Con $n = 1\,000\,000$ eso fue la diferencia entre un error de $9.58\times10^{2}$ y uno de $5.88\times10^{-4}$: casi un millón de veces más grande en el caso 1.

La razón de fondo, según lo que puedo explicar con lo visto en clase, es que el épsilon de máquina mide una precisión **relativa**, no un error absoluto fijo. Como el acumulador del caso 1 crece de forma sostenida, el tamaño del redondeo también va creciendo con él, y como todos esos redondeos van en la misma dirección, se van sumando entre sí. En el caso 2 el acumulador se queda mucho más chico en promedio (porque los signos se cancelan) y además los propios errores de redondeo se cancelan parcialmente entre ellos.
"

# ╔═╡ 6088a41b-3ff7-4c20-aa5e-860dd7170920
md"
## 7. ¿Qué cambió en mi comprensión?

Al empezar, yo tenía en la cabeza que el épsilon de máquina era casi como una unidad de error fija que se 'pegaba' una vez por cada operación, entonces para mí sumar $n$ veces siempre debía dar un error del orden de $n \cdot \epsilon_{32}$, sin importar los signos. Esa era mi predicción y me parecía razonable porque es literalmente lo único que habíamos visto en clase: representación y épsilon de máquina, nada sobre cómo se van acumulando los errores a lo largo de muchas operaciones.

Lo que no había entendido es que el épsilon de máquina es una cota **relativa**, entonces el tamaño real de cada redondeo depende de qué tan grande sea el número que se está representando en ese momento, no es un número fijo. Eso quiere decir que si el acumulador va creciendo (como en el caso 1), cada suma nueva no comete el mismo error que la anterior, comete uno más grande, y si además esos errores no se cancelan entre sí porque siempre van en la misma dirección, el efecto se acumula muchísimo más rápido de lo que yo pensaba.

Lo más inesperado para mí fue justamente eso: que la misma cantidad de sumas, en el mismo formato, con números de la misma magnitud, pudiera dar errores que difieren en varios órdenes de magnitud solo por el signo con el que se van acumulando. Antes de este ejercicio yo hubiera dicho que 'más operaciones = más error' de forma bastante pareja entre los dos casos, y ahora entiendo que importa muchísimo si esas operaciones tienden a empujar el resultado siempre en la misma dirección o si se van cancelando entre sí.
"

# ╔═╡ a7a762c9-f0e3-493d-91b1-c7837fb0f1e6
md"
## Uso de inteligencia artificial

- **Asistente utilizado:** Claude.
- **Para qué lo utilicé:** principalmente para hacer código de julia porque es un lenguaje totalmente nuevo para mí, además de resolver con flotantes de mayor magnitud para mas presición en el informe.  

- **Preguntas importantes que le hice:**
  1. Le pregunté cómo medir qué tanto estaba relacionandose la cantidad de veces que se suma la variable con el error acumulado; de ahí me sugirió la función pendiente_log() y se dice que un número cercano a 1 es una relación lineal.
  2. Le pregunté por qué el error de sumar siempre el mismo número no crecía proporcional a $n$ sino mucho más rápido, porque a mí me había dado una pendiente de casi $2$ en la gráfica log-log y no entendía de dónde salía eso.
  3. Le pregunté cómo podía comparar mi resultado en Float32 contra un valor 'de verdad' confiable sin tener que hacer las cuentas a mano, y ahí fue cuando propuso usar `BigFloat` como referencia.

- **Algo que tuve que verificar o cuestionar:** al principio el experimento con signos aleatorios solo corría una vez por cada $n$, pero la IA me dijo que para conseguir valores reales debía hacer algunas iteraciones y promediar el error de todas ellas, para que un caso particular no me dañara todo el análisis.
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "222ce4b6ad9a64f0226d6727cd8d0fc2ec843983"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "e2b53ce13a53367e96601081e33d34746b571bad"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.5"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"
"""

# ╔═╡ Cell order:
# ╠═570241bb-942a-43df-8572-6af37d737bc7
# ╠═6e40e6a9-cbdb-47a5-a926-35da7b031533
# ╠═e8793e6b-8ac2-46f9-a2fa-fb2366a4dc77
# ╠═1c7b4d54-ac2d-495a-9fa0-ee7e3fbb74c3
# ╠═a12c089d-621c-44cf-ab6a-86b1b1ff7d13
# ╠═2b19a97e-38ea-4f3d-b757-f391b988e819
# ╠═1a7c5cdb-d277-4380-a779-ef19e981d910
# ╠═e6b56453-7fb1-4290-88a7-f1664d1f1085
# ╠═601084a6-fb55-410e-903f-5bef74eae216
# ╠═eafbb3ef-db4c-4895-82e3-53bb89dda614
# ╠═23c1b2b4-ed53-4fd0-add0-867f22a611dd
# ╠═f847c3dd-8343-42fa-a377-1628fb4e58e6
# ╠═b6b5704a-f970-42c4-a8ec-746bda648209
# ╠═1c4b3be9-10d3-413c-826a-90ce91917dde
# ╠═a535cbe1-ff5b-4fe1-9704-b14a3024dec5
# ╠═6088a41b-3ff7-4c20-aa5e-860dd7170920
# ╠═a7a762c9-f0e3-493d-91b1-c7837fb0f1e6
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

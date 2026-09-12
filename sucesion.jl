### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 85f03c14-aeba-11f1-8d9b-adb650c5d0fe
md"
# ¿Puede el computador representar cualquier valor de la serie $x_{n+1} = 11 x_{n} - 2$ usando por valor inicial $0.2$ en formato Float32?

Según lo visto en clase, $0.2 = \frac{1}{5} = (1.\overline{1001})_2 \cdot 2^{-3}$, entonces, tiene por número de máquina 

$$0 \quad 01111100 \quad 10011001100110011001101$$

Es decir, $0.2$ no es representable en formato de 32 bits, lo que me hace formularme la pregunta: ¿Usar este número una gran cantidad de veces hará que el error de truncamiento lance valores que no corresponden a la serie ¿$x_{n+1} = 11 x_{n} - 2$?


Sabemos que para todo valor de $n$, $x_n = 0.2$, pues $x_1 = 11 \cdot 0.2 - 2 = 2.2 - 2 = 0.2$ (se usa este resultado de manera inductiva para saber que $x_n = 0.2$).


Escogí esta situación para experimentar el efecto del error en operaciones de máquina simultanea y cómo puede afectar el acumulamiento de errores en las operaciones siguientes.




Mi hipótesis sobre esto es que el error va a producir números distintos y conforme se hagan más iteraciones sobre el valor de $n$ el error se amplifica.
"

# ╔═╡ 58f8587b-d3f3-4413-a311-082016f30c41
md"
Antes que nada, según lo visto en clase, el error de haber representado $0.2$ en un número de máquina sería $\epsilon = \frac{1}{5} 2^{-26} \approx 2.9802322387695314 \times 10^{-9}$. 

Entonces la sucesión evaluada por la máquina ($\tilde{x}_n$) tendría la siguiente forma:


$x_0 = 0.2 + \epsilon$
$x_1 = 11 \cdot (0.2 + \epsilon) - 2 = 11 \cdot 0.2 - 2 + 11 \epsilon$
$x_2 = 11(11 \cdot 0.2 - 2 + 11 \epsilon) - 2 = 11^2 \cdot 0.2 + 11^2 \epsilon - 24$

De aquí se puede observar que el error $\epsilon$ se amplifica conforme crece el valor de $n$, en el siguiente código se pueden observar los primeros $10$ valores de la serie truncada.
"

# ╔═╡ 9f56da90-341c-4a81-b215-52dee6e54e35
function sucesion(n::Integer)::Float32
    if n == 0
        return 0.2f0
    end
    return 11f0 * sucesion(n - 1) - 2f0
end

# ╔═╡ f53fc5d5-e065-40d9-b099-ed14e2171f3e
for i in 1:10
    println(sucesion(i))
end

# ╔═╡ bd33ebb7-336d-4499-8922-5cf9cca09857
md"
De aqui podemos ver que mi hipótesis se cumplió, y además se puede observar que la presición de $0.2$ se mantuvo solamente durante 6 iteraciones de la función (hasta la segunda cifra representativa). 


Además también se nota que una vez se alcanza la iteración $8$ el error se emplifica de forma exponencial, tal cual como se propuso en la segunda celda de este notebook.
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "71853c6197a6a7f222db0f1978c7cb232b87c5ee"

[deps]
"""

# ╔═╡ Cell order:
# ╠═85f03c14-aeba-11f1-8d9b-adb650c5d0fe
# ╠═58f8587b-d3f3-4413-a311-082016f30c41
# ╠═9f56da90-341c-4a81-b215-52dee6e54e35
# ╠═f53fc5d5-e065-40d9-b099-ed14e2171f3e
# ╠═bd33ebb7-336d-4499-8922-5cf9cca09857
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

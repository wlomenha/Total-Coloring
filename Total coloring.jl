using DelimitedFiles, JuMP, Gurobi 

function adj_matrix_to_edges(A)
    n = size(A, 1)
    edges = []
    for i in 1:n
        for j in i+1:n
            if A[i,j] == 1
                push!(edges, (i,j))
            end
        end
    end
    return edges
end

path = "D:\\GitHub - Projects\\Total Coloring\\randomgraph3regular.txt"

# Inicialização da matriz de adjacência
n = 8
A = zeros(Int, n, n)


# Leitura do arquivo e preenchimento da matriz
open(path, "r") do file
    for i in 1:n
        line = readline(file)
        line = replace(line, r"[\[\]]" => "") # Remove os colchetes
        values = split(line)
        for j in 1:n
            A[i, j] = parse(Int, values[j])
        end
    end
end

edges = adj_matrix_to_edges(A)

n = size(A, 1)
m = sum(A) ÷ 2
C = 1:5
V = 1:n



model = Model(Gurobi.Optimizer)

@variable(model, z[c in C], Bin)

# Variáveis de decisão para vértices
@variable(model, x[i in V, c in C], Bin)

# Variáveis de decisão para arestas
#@variable(model, y[i in V, j in V, c in C], Bin)
@variable(model, y[e in edges, c in C], Bin)

# Restrição de coloração de vértices
@constraint(model, [i in V], sum(x[i,c] for c in C) == 1)

# Restrição de coloração de arestas
@constraint(model, [e in edges], sum(y[e,c] for c in C) == 1)

#Restrição de coloração de vértices adjacentes
@constraint(model, neighbor_vertex[i in V, j in V, c in C; i != j && A[i,j] == 1], x[i,c] + x[j,c] <= z[c])

#Restrição de coloração de arestas adjacentes #PROBLEMA
@constraint(model, neighbor_edges[i in V, j in V, c in C; i != j], x[i,c] + sum(y[i,j,c] ))

#Restrição vértice e aresta possuirem cores distintas
@constraint(model, neigbors_vertex_edges[i in V, j in V, c in C], x[i,c] + x[j,c] + y[i,j,c] <= z[c])

# Restrição de coloração entre vértices e arestas #PROBLEMA
@constraint(model, [i in V, j in V, c in C], (i,j) in edges => x[i,c] + x[j,c] - y[i,j,c] <= 1)


# Função objetivo de minimização da quantidade de cores usadas
@objective(model, Min, sum(z))

# Resolve o modelo
optimize!(model)

opt = objective_value(model)

# Mostra a solução
println("Número mínimo de cores necessárias: ", objective_value(model))
for i in 1:n
    for j in i+1:n
        for c in C
            if value(y[i,j,c]) > 0.5
                println("Aresta entre os vértices ", i, " e ", j, " colorida com a cor ", c)
            end
        end
    end
end
for i in 1:n
    for c in C
        if value(x[i,c]) > 0.5
            println("Vértice ", i, " colorido com a cor ", c)
        end
    end
end






















model = Model(Gurobi.Optimizer)

# Variáveis de decisão para vértices
@variable(model, x[i in V, c in C], Bin)

# Variáveis de decisão para arestas
@variable(model, y[e in edges, c in C], Bin)

# Variáveis de decisão para cores
@variable(model, z[i in C], Bin)

# Função objetivo
@objective(model, Min, sum(z))

# Restrição de coloração de vértices
@constraint(model, [i in V], sum(x[i, c] for c in C) == 1)

# Restrição de coloração de arestas
@constraint(model, [e in edges], sum(y[e, c] for c in C) == 1)

# Restrição de conflito de cores em vértices e arestas
@constraint(model, [i in V, c in C], x[i, c] + sum(y[e, c] for e in edges if e[1] == i || e[2] == i) <= z[c])
@constraint(model, [e in edges, c in C], x[e[1], c] + x[e[2], c] + y[e, c] <= z[c])

# Resolvendo o modelo
optimize!(model)

# Imprimindo a solução
println("Valor ótimo da função objetivo: ", objective_value(model))
for i in V
    for c in C
        if value(x[i, c]) > 0.5
            println("Vértice ", i, " é da cor ", c)
        end
    end
end

# Loop para imprimir a solução das cores das arestas
for e in edges
    for c in C
        if value(y[e, c]) > 0.5
            println("Aresta", e, " é da cor ", c)
        end
    end
end
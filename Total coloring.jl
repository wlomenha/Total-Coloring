using DelimitedFiles, JuMP, Gurobi 

#Contrução das arestas
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

path = "D:\\GitHub - Projects\\Total Coloring\\G(2,0) Fullerene.txt"

# Inicialização da matriz de adjacência
n = 80
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

m = length(edges)
C = 1:4
V = 1:n

model = Model(Gurobi.Optimizer)

# Variáveis de decisão para vértices
@variable(model, x[i in V, c in C], Bin)

# Variáveis de decisão para arestas
@variable(model, y[e in edges, c in C], Bin)

# Função objetivo de minimização da quantidade de cores usadas
@objective(model, Min, sum(x)+sum(y))

# Restrição de coloração de vértices
@constraint(model, [i in V], sum(x[i,c] for c in C) == 1)

# Restrição de coloração de arestas adjacentes
@constraint(model, [e in edges], sum(y[e,c] for c in C) == 1)

#Restrição de coloração de vértices adjacentes
@constraint(model, neighbor_vertex[i in V, j in V, c in C; i != j && A[i,j] == 1], x[i,c] + x[j,c] <= 1)

#Restrição vértice e aresta possuirem cores distintas
@constraint(model, neigbors_vertex_edges[e in edges, c in C], x[e[1],c] + x[e[2],c] + y[e,c] <= 1)


#Restrição de coloração de arestas adjacentes #PROBLEMA
@constraint(model, neighbor_edges_1[i in V, c in C], sum(y[(i,j),c] for j in V if (i,j) in edges && i != j) + sum(y[(j,i),c] for j in V if (j,i) in edges && i != j) <= 1)


# Resolve o modelo
optimize!(model)

opt = objective_value(model)

# Mostra a solução
println("Número mínimo de cores necessárias: ", objective_value(model))

for e in edges
    for c in C
        if value(y[e,c]) > 0.5
            println("Aresta ", e[1] -1,"  " , e[2] - 1 ," colorida com a cor ", c)
        end
    end
end

for i in 1:n
    for c in C
        if value(x[i,c]) > 0.5
            println("Vértice ", i-1, " colorido com a cor ", c)
        end
    end
end
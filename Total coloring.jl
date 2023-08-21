using DelimitedFiles, JuMP, Gurobi

# Convert adjacency matrix to a list of edges
function adj_matrix_to_edges(A::Matrix{Int})
    n, m = size(A)
    edges = []
    for i in 1:n
        for j in i+1:m
            if A[i,j] == 1
                push!(edges, (i,j))
            end
        end
    end
    return edges
end

# Read the adjacency matrix from a text file
function read_adjacency_matrix(path::String)
    # Open the file for reading
    lines = readlines(path)
    
    # Extract values from each line and construct the adjacency matrix
    A = [parse(Int, v) for line in lines for v in split(replace(line, r"[\[\]]" => ""))]
    
    # Reshape the vector to a matrix
    n = Int(sqrt(length(A)))
    return reshape(A, n, n)
end

# Total Coloring optimization model
function total_coloring(A::Matrix{Int}, colors)
    edges = adj_matrix_to_edges(A)
    m = length(edges)
    C = 1:colors
    V = 1:size(A,1)
    
    model = Model(Gurobi.Optimizer)

    # Decision variables for vertices
    @variable(model, x[i in V, c in C], Bin)

    # Decision variables for edges
    @variable(model, y[e in edges, c in C], Bin)

    # Objective: minimize the total number of colors used
    @objective(model, Min, sum(x) + sum(y))

    # Constraint: each vertex has exactly one color
    @constraint(model, [i in V], sum(x[i,c] for c in C) == 1)

    # Constraint: each edge has exactly one color
    @constraint(model, [e in edges], sum(y[e,c] for c in C) == 1)

    # Constraint: adjacent vertices have different colors
    @constraint(model, [i in V, j in V, c in C; i != j && A[i,j] == 1], x[i,c] + x[j,c] <= 1)

    # Constraint: an edge and its vertices cannot have the same color
    @constraint(model, [e in edges, c in C], x[e[1],c] + x[e[2],c] + y[e,c] <= 2)

    # Constraint: adjacent edges have different colors
    @constraint(model, [i in V, c in C], sum(y[(i,j),c] for j in V if (i,j) in edges) + sum(y[(j,i),c] for j in V if (j,i) in edges) <= 1)

    # Solve the model
    optimize!(model)
    
    # Return the model for further analysis if needed
    return model
end

# Main function to execute the program
function main(path::String,  colors)
    A = read_adjacency_matrix(path)
    model = total_coloring(A, colors)
    
    println("Número mínimo de cores necessárias: ", objective_value(model))
    
    for e in adj_matrix_to_edges(A)
        for c in 1:colors
            if value(model[:y][e,c]) > 0.5
                println("Aresta ($(e[1]),$(e[2])) colorida com a cor ", c)
            end
        end
    end
    
    for i in 1:size(A,1)
        for c in 1:colors
            if value(model[:x][i,c]) > 0.5
                println("Vértice ", i, " colorido com a cor ", c)
            end
        end
    end
end

# Call the main function with the desired path
path = "D:\\GitHub - Projects\\Total Coloring\\newrandom3regulargraph.txt"
colors = 4
main(path, colors)
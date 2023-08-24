using DelimitedFiles, JuMP, Gurobi, Pkg, Graphs, GraphPlot, Colors, Cairo, Fontconfig

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
    @constraint(model, [e in edges, c in C], x[e[1],c] + x[e[2],c] + y[e,c] <= 1)

    # Constraint: adjacent edges have different colors
    @constraint(model, [i in V, c in C], sum(y[(i,j),c] for j in V if (i,j) in edges) + sum(y[(j,i),c] for j in V if (j,i) in edges) <= 1)

    #Force Coloring of some vertices
    # fix(x[1,1],1.0)
    # fix(x[2,4],1.0)
    # fix(x[3,2],1.0)
    # fix(x[4,4],1.0)
    # fix(x[5,2],1.0)

    # fix(x[12,4],1.0)
    # fix(x[13,2],1.0)
    # fix(x[32,4],1.0)
    # fix(x[31,1],1.0)
    # fix(x[30,2],1.0)

    # fix(x[9,4],1.0)
    # fix(x[10,2],1.0)
    # fix(x[28,4],1.0)
    # fix(x[27,1],1.0)
    # fix(x[26,2],1.0)

    # fix(x[6,4],1.0)
    # fix(x[7,2],1.0)
    # fix(x[24,4],1.0)
    # fix(x[20,1],1.0)
    # fix(x[22,2],1.0)

    # fix(x[18,4],1.0)
    # fix(x[19,2],1.0)
    # fix(x[20,4],1.0)
    # fix(x[39,1],1.0)
    # fix(x[38,2],1.0)

    # fix(x[15,4],1.0)
    # fix(x[16,2],1.0)
    # fix(x[36,4],1.0)
    # fix(x[35,1],1.0)
    # fix(x[34,2],1.0)

    # fix(x[53,4],1.0)
    # fix(x[54,1],1.0)
    # fix(x[55,2],1.0)
    # fix(x[71,2],1.0)
    # fix(x[72,4],1.0)

    # fix(x[50,1],1.0)
    # fix(x[49,4],1.0)
    # fix(x[51,2],1.0)
    # fix(x[68,2],1.0)
    # fix(x[69,4],1.0)

    # fix(x[46,1],1.0)
    # fix(x[45,4],1.0)
    # fix(x[47,2],1.0)
    # fix(x[66,4],1.0)
    # fix(x[65,2],1.0)

    # fix(x[41,4],1.0)
    # fix(x[42,1],1.0)
    # fix(x[43,2],1.0)
    # fix(x[63,4],1.0)
    # fix(x[62,2],1.0)

    # fix(x[57,4],1.0)
    # fix(x[58,1],1.0)
    # fix(x[59,2],1.0)
    # fix(x[60,4],1.0)
    # fix(x[74,2],1.0)

    # fix(x[75,4],1.0)
    # fix(x[76,2],1.0)
    # fix(x[77,4],1.0)
    # fix(x[78,2],1.0)
    # fix(x[79,1],1.0)


    # Solve the model
    optimize!(model)
    
    # Return the model for further analysis if needed
    return model
end

function plot_colored_graph(A::Matrix{Int}, model)
    # Create a graph from the adjacency matrix
    g = SimpleGraph(A)

    # Extract the edges and vertices' colors from the model's solution
    edge_colors = Dict()
    vertex_colors = Dict()
    C = 1:4
    color_map = [colorant"red", colorant"blue", colorant"green", colorant"yellow"]  # You can modify the color list as per your preference

    for e in edges(g)
        for c in C
            if value(model[:y][(src(e), dst(e)), c]) > 0.5
                edge_colors[e] = color_map[c]
                break
            end
        end
    end

    for v in vertices(g)
        for c in C
            if value(model[:x][v, c]) > 0.5
                vertex_colors[v] = color_map[c]
                break
            end
        end
    end

    # Plot the graph with colored edges and vertices
    nodefillc = [vertex_colors[v] for v in vertices(g)]
    edgestrokec = [edge_colors[e] for e in edges(g)]
    
   # Adjusting the layout function for gplot
   layout_func(g) = spring_layout(g)
    
   # Display the graph directly
   node_labels = [string(v) for v in vertices(g)]
   display(gplot(g, nodelabel = node_labels, nodefillc=nodefillc, edgestrokec=edgestrokec, layout=layout_func))
    
    println("Graph has been saved as colored_graph.png")
end

# Main function to execute the program
function main(path::String,  colors)
    A = read_adjacency_matrix(path)
    model = total_coloring(A, colors)
    plot_colored_graph(A,model)
    
    println("Número mínimo de cores necessárias: ", objective_value(model))
    
    for e in adj_matrix_to_edges(A)
        for c in 1:colors
            if value(model[:y][e,c]) > 0.5
                println("Aresta ($(e[1]-1),$(e[2]-1)) colorida com a cor ", c)
            end
        end
    end
    
    for i in 1:size(A,1)
        for c in 1:colors
            if value(model[:x][i,c]) > 0.5
                println("Vértice ", i-1, " colorido com a cor ", c)
            end
        end
    end
end

# Call the main function with the desired path
path = "D:\\GitHub - Projects\\Total Coloring\\random3regulargraph10vertices.txt"
colors = 4
main(path, colors)
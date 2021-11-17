function kron_reduction(
    Y::SparseMatrixCSC{ComplexF64, Int64},
    obs::Vector{Int64},
    nobs::Vector{Int64};
    alpha = 1E-1::Float64
)
    Nobs = length(obs)
    Nnobs = length(nobs)
    Y11 = Y[obs, obs]
    Y12 = Y[obs, nobs]
    Y21 = Y[nobs, obs]
    Y22 = Y[nobs, nobs]
    Yr = Y11 - Y12 * (Y22 \ Matrix{ComplexF64}(Y21)) 
    thres = alpha * minimum(abs.(Y.nzval))
    epsilon_r = zeros(0,2)
    y_r = Vector{ComplexF64}([])
    for i in 1:Nobs
        for j in i+1:Nobs
            if(abs(Yr[i,j]) > thres)
                epsilon_r = vcat(epsilon_r, [i j])
                append!(y_r, -Yr[i, j])
            end
        end
    end
    epsilon_r = Int64.(epsilon_r)
    Nline = size(epsilon_r, 1)
    id2 = [epsilon_r[:,1]; epsilon_r[:,2]]
    id1 = [1:Nline; 1:Nline]
    values = [ones(Nline); -ones(Nline)]
    Bm = sparse(id1, id2, values, size(epsilon_r,1), Nobs, Nline)
    ysh_r = diag(Yr) - Vector{ComplexF64}(diag(Bm' * sparse(1:Nline, 1:Nline, y_r) * Bm))
    return  y_r, ysh_r, epsilon_r
end


function build_admittance_matrix(
    b::Vector{Float64},
    g::Vector{Float64},
    bsh::Vector{Float64},
    gsh::Vector{Float64},
    epsilon::Matrix{Int64}
)
    Nline = size(epsilon,1)
    Nbus = maximum(epsilon)
    println([Nline Nbus])
    Bm = sparse([epsilon[:,1]; epsilon[:,2]], [1:Nline; 1:Nline],
        [-ones(Nline); ones(Nline)], Nbus, Nline)
    return Bm * sparse(1:Nline, 1:Nline, g+im*b) * Bm' + 
        sparse(1:Nbus, 1:Nbus, gsh+im*bsh)
end

using ComponentArrays
using DifferentialEquations
using Parameters: @unpack


tspan = (0.0, 20.0)


## Lorenz system
function lorenz!(D, u, (p, f), t)
    @unpack σ, ρ, β = p
    @unpack x, y, z = u
    
    D.x = σ*(y - x)
    D.y = x*(ρ - z) - y + f
    D.z = x*y - β*z
    return nothing
end
function lorenz_jac!(D, u, (p, f), t)
    @unpack σ, ρ, β = p
    @unpack x, y, z = u
    
    D[:x,:x] = -σ
    D[:x,:y] = σ
    D[:x,:z] = 0

    D[:y,:x] = ρ
    D[:y,:y] = -1
    D[:y,:z] = -x

    D[:z,:x] = y
    D[:z,:y] = x
    D[:z,:z] = -β
    return nothing
end

lorenz_p = (σ=10.0, ρ=28.0, β=8/3)
lorenz_ic = CArray(x=0.0, y=0.0, z=0.0)
lorenz_fun = ODEFunction(lorenz!, jac=lorenz_jac!)
lorenz_prob = ODEProblem(lorenz_fun, lorenz_ic, tspan, (lorenz_p, 0.0))


## Lotka-Volterra system
function lotka!(D, u, (p, f), t)
    @unpack α, β, γ, δ = p
    @unpack x, y = u
    
    D.x =  α*x - β*x*y + f
    D.y = -γ*y + δ*x*y
    return nothing
end
function lotka_jac!(D, u, (p, f), t)
    @unpack α, β, γ, δ = p
    @unpack x, y = u
    
    D[:x,:x] = α
    D[:x,:y] = -β*x

    D[:y,:x] = δ*x
    D[:y,:y] = -γ
    return nothing
end

lotka_p = (α=2/3, β=4/3, γ=1.0, δ=1.0)
lotka_ic = CArray(x=1.0, y=1.0)
lotka_fun = ODEFunction(lotka!, jac=lotka_jac!)
lotka_prob = ODEProblem(lotka_fun, lotka_ic, tspan, (lotka_p, 0.0))


## Composed Lorenz and Lotka-Volterra system
function composed!(D, u, p, t)
    c = p.c #coupling parameter
    @unpack lorenz, lotka = u
    
    lorenz!(D.lorenz, lorenz, (p.lorenz, -c*lotka.x), t)
    lotka!(D.lotka, lotka, (p.lotka, c*lorenz.x), t)
    return nothing
end
function composed_jac!(D, u, p, t)
    c = p.c
    @unpack lorenz, lotka = u
    
    lorenz_jac!(D[:lorenz,:lorenz], lorenz, (p.lorenz, 0), t)
    lotka_jac!(D[:lotka,:lotka], lotka, (p.lotka, 0), t)

    D[:lorenz,:lotka][:y,:x] = -c
    D[:lotka,:lorenz][:x,:x] = c
    return nothing
end

comp_p = (lorenz=lorenz_p, lotka=lotka_p, c=0.01)
comp_ic = CArray(lorenz=lorenz_ic, lotka=lotka_ic)
comp_fun = ODEFunction(composed!, jac=composed_jac!)
comp_prob = ODEProblem(comp_fun, comp_ic, tspan, comp_p)


## Solve problem
# We can solve the composed system...
comp_sol = solve(comp_prob, alg_hints=[:stiff])

# ...or we can unit test one of the component systems
lotka_sol = solve(lotka_prob, alg_hints=[:stiff])
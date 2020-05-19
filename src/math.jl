## Linear Algebra
Base.pointer(x::ComponentArray) = pointer(getdata(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::ComponentArray) where T = Base.unsafe_convert(Ptr{T}, getdata(x))

Base.adjoint(x::CVector) = ComponentArray(adjoint(getdata(x)), FlatAxis(), getaxes(x)[1])
Base.adjoint(x::CMatrix) = ComponentArray(adjoint(getdata(x)), reverse(getaxes(x))...)

Base.transpose(x::CVector) = ComponentArray(transpose(getdata(x)), FlatAxis(), getaxes(x)[1])
Base.transpose(x::CMatrix) = ComponentArray(transpose(getdata(x)), reverse(getaxes(x))...)

const AdjointVector{T,A} = Union{Adjoint{T,A}, Transpose{T,A}} where A<:AbstractVector{T}
const AdjointCVector{Axes,T,A} = CMatrix{Axes,T,A} where A<:AdjointVector

Base.:(*)(x::AdjointCVector, y::AbstractArray{<:T,<:N}) where {T,N} = ComponentArray(getdata(x)*y, getaxes(x)...)

Base.:(\)(x::CMatrix, y::AbstractVecOrMat) = getdata(x) \ y
Base.:(/)(x::AbstractVecOrMat, y::CMatrix) = x / getdata(y)

Base.inv(x::CMatrix) = inv(getdata(x))


## Vector to matrix concatenation
Base.hcat(x1::CVector, x2::CVector) = ComponentArray(hcat(getdata.((x1, x2))...), getaxes(x1)[1], FlatAxis())
Base.vcat(x1::AdjointCVector, x2::AdjointCVector) = ComponentArray(vcat(getdata(x1), getdata(x2)), FlatAxis(), getaxes(x1)[2])
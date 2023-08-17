"""
Placeholder for a short summary about TaggedAxisArrays.
"""
module TaggedAxisArrays

export TaggedAxisArray, TaggedAxisVector, TaggedAxisMatrix, Tag, NoTag, tags, tag_nth

using ArgCheck: @argcheck
using DocStringExtensions: SIGNATURES

####
#### axes and wrapping
####

struct TaggedAxis{S,T,A<:AbstractUnitRange{T}} <: AbstractUnitRange{T}
    tag::S
    parent_axis::A
end

Base.parent(a::TaggedAxis) = a.parent_axis
Base.axes(a::TaggedAxis) = axes(a.parent_axis)
Base.length(a::TaggedAxis) = length(a.parent_axis)
Base.first(a::TaggedAxis) = first(a.parent_axis)
Base.last(a::TaggedAxis) = last(a.parent_axis)
Base.isempty(a::TaggedAxis) = isempty(a.parent_axis)
Base.getindex(a::TaggedAxis, i::Integer) = getindex(a.parent_axis, i)

function Base.:(==)(a1::TaggedAxis, a2::TaggedAxis)
    a1.tag == a2.tag && a1.parent_axis == a2.parent_axis
end

# function Base.:(==)(a1::TaggedAxis, a2::AbstractUnitRange)
#     a1.tag ≡ nothing && a1 == a2
# end

# Base.:(==)(a1::AbstractUnitRange, a2::TaggedAxis) = a2 == a1

function Base.show(io::IO
                   , tagged_axis::TaggedAxis)
    (; tag, parent_axis) = tagged_axis
    print(io, parent_axis, " tagged ", tag)
end

struct Tag{S}
    tag::S
    function Tag(tag::S) where S
        new{S}(tag)
    end
end

struct NoTag end

_tag_axis(tag::Tag, axis) = TaggedAxis(tag.tag, axis)
_tag_axis(::NoTag, axis) = axis

_tag_of_axis(a::TaggedAxis) = Tag(a.tag)
_tag_of_axis(a) = NoTag()

const NTags{N} = NTuple{N,Union{Tag,NoTag}}

####
#### array
####

struct TaggedAxisArray{T,N,P<:AbstractArray{T,N},G<:NTags{N}} <: AbstractArray{T,N}
    parent::P
    tags::G
end

"""
$(SIGNATURES)

The tags of the array as a `Tuple`. `NoTag()` stands for untagged axes.
"""
tags(A::TaggedAxisArray) = A.tags

TaggedAxisArray(A::TaggedAxisArray, tags) = TaggedAxisArray(parent(A), tags)

const TaggedAxisVector{T,P<:AbstractVector{T}} = TaggedAxisArray{T,1,P}

TaggedAxisVector(v::AbstractVector, tag::Tag) = TaggedAxisArray(v, (tag, ))

const TaggedAxisMatrix{T,P<:AbstractMatrix{T}} = TaggedAxisArray{T,2,P}

function TaggedAxisMatrix(v::AbstractVector, tag1::Tag, tag2::Tag)
    TaggedAxisArray(v, (tag1, tag2))
end

struct TagNth{N,S}
    tag::S
end

tag_nth(::Val{N}, tag) where N = TagNth{N}(tag)

@inline tag_nth(N::Int, tag) = tag_nth(Val(N), tag)

function TaggedAxisArray(parent::AbstractArray{T,N}, tn::TagNth{M}) where {T,N,M}
    @argcheck 1 ≤ M ≤ N "Cannot tag axis $(M) in an $(N)-dimensional array"
    tags = ntuple(n -> n == M ? Tag(tag) : NoTag(), Val(N))
    TaggedAxisArray(parent, tags)
end

@inline _parent_type(A::TaggedAxisArray{P}) where P = P

@inline Base.parent(A::TaggedAxisArray) = A.parent

@inline Base.size(A::TaggedAxisArray) = size(A.parent)

@inline Base.getindex(A::TaggedAxisArray, ι...) = getindex(A.parent, ι...)

@inline Base.setindex!(A::TaggedAxisArray, vι...) = setindex!(A.parent, vι...)

Base.IndexStyle(::Type{A}) where {A<:TaggedAxisArray} = IndexStyle(_parent_type(A))

function Base.axes(A::TaggedAxisArray)
    (; parent, tags) = A
    map(_tag_axis, tags, axes(parent))
end

function Base.similar(A::TaggedAxisArray, args...)
    # FIXME this does not handle tags and needs to be fixed
    (; parent, tags) = A
    TaggedAxisArray(Base.similar(parent, args...), tags)
end

###
### strided arrays
###

Base.strides(A::TaggedAxisArray) = strides(A.parent)

Base.elsize(::Type{A}) where {A <: TaggedAxisArray} = Base.elsize(_parent_type(A))

@inline function Base.unsafe_convert(::Type{Ptr{T}}, A::TaggedAxisArray{T}) where {T}
    Base.unsafe_convert(Ptr{T}, parent(A))
end

###
### broadcasting
###

import Base.Broadcast: Broadcasted, BroadcastStyle

struct TaggedAxisStyle <: BroadcastStyle end

BroadcastStyle(::Type{<:TaggedAxisArray}) = TaggedAxisStyle()

BroadcastStyle(a::TaggedAxisStyle, _) = a # currently, we trump anything, fix later

function Base.similar(bc::Broadcast.Broadcasted{<:TaggedAxisStyle}, ::Type{T}) where {T}
    tags = map(_tag_of_axis, axes(bc))
    TaggedAxisArray(similar(Array{T}, map(parent, bc.axes)), tags)
end

end # module

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

function Base.show(io::IO
                   , tagged_axis::TaggedAxis)
    (; tag, parent_axis) = tagged_axis
    print(io, parent_axis, " tagged ", tag)
end

struct Tag{S}
    tag::S
    """
    $(SIGNATURES)

    Tag the corresponding axis with the argument, which can be an arbitrary value. Tags are
    considered the same when `==`.
    """
    function Tag(tag::S) where S
        new{S}(tag)
    end
end

"""
    NoTag()

Don't tag the corresponding axis.
"""
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
    function TaggedAxisArray(parent::P, tags::G) where {T,N,P<:AbstractArray{T,N},G<:NTags{N}}
        @argcheck !Base.has_offset_axes(parent) "No offset axes yet, mean to fix this later."
        new{T,N,P,G}(parent, tags)
    end
end

"""
$(SIGNATURES)

The tags of the array as a `Tuple`. `NoTag()` stands for untagged axes.
"""
tags(A::TaggedAxisArray) = A.tags

"""
$(SIGNATURES)

Wrap an array, optionally tagging each axis with the given tags, which can be `Tag(tag)` or
`NoTag()`.
"""
TaggedAxisArray(A::TaggedAxisArray, tags::Tuple) = TaggedAxisArray(parent(A), tags)

const TaggedAxisVector{T,P<:AbstractVector{T}} = TaggedAxisArray{T,1,P}

TaggedAxisVector(v::AbstractVector, tag::Tag) = TaggedAxisArray(v, (tag, ))

const TaggedAxisMatrix{T,P<:AbstractMatrix{T}} = TaggedAxisArray{T,2,P}

function TaggedAxisMatrix(v::AbstractVector, tag1::Tag, tag2::Tag)
    TaggedAxisArray(v, (tag1, tag2))
end

struct TagNth{N,S}
    tag::S
end

"""
$(SIGNATURES)

Tag the `nth` index with the given tag.

# Example

```julia
TaggedAxisArray(randn(3, 3, 3), tag_nth(3, "my tag"))
```
"""
tag_nth(::Val{N}, tag) where N = TagNth{N}(tag)

@inline tag_nth(N::Int, tag) = tag_nth(Val(N), tag)

function TaggedAxisArray(parent::AbstractArray{T,N}, tn::TagNth{M}) where {T,N,M}
    @argcheck 1 ≤ M ≤ N "Cannot tag axis $(M) in an $(N)-dimensional array"
    tags = ntuple(n -> n == M ? Tag(tag) : NoTag(), Val(N))
    TaggedAxisArray(parent, tags)
end

@inline _parent_type(::Type{<:TaggedAxisArray{T,N,P}}) where {T,N,P} = P

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

# FIXME currently, we trump anything, fix later
BroadcastStyle(a::TaggedAxisStyle, ::BroadcastStyle) = a

function Base.similar(bc::Broadcast.Broadcasted{<:TaggedAxisStyle}, ::Type{T}) where {T}
    tags = map(_tag_of_axis, axes(bc))
    # FIXME this is unsatisfactory since we only deal with regular indexing
    TaggedAxisArray(similar(Array{T}, map(length ∘ parent, bc.axes)), tags)
end

end # module

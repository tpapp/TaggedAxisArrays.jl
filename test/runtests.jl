using TaggedAxisArrays
using Test

a1 = TaggedAxisVector(1:4, Tag(1))
a2 = TaggedAxisVector(1:4, Tag(2))

@test a1 == a1
@test a1 != a2

@test_throws DimensionMismatch a1 .+ a2
@test a1 .+ a1 == TaggedAxisArray(parent(a1) .+ parent(a1), tags(a1))

b = 1:2
@test a1 .+ b' == TaggedAxisArray(parent(a1) .+ b', (tags(a1)..., NoTag()))

m = reshape(1:15, 3, :)
tm = TaggedAxisMatrix(m, NoTag(), Tag("t"))
# @test tags(collect(eachcol(tm))) == (Tag("t"),)

## NOTE add JET to the test environment, then uncomment
# using JET
# @testset "static analysis with JET.jl" begin
#     @test isempty(JET.get_reports(report_package(TaggedAxisArrays, target_modules=(TaggedAxisArrays,))))
# end

# @testset "QA with Aqua" begin
#     import Aqua
#     Aqua.test_all(TaggedAxisArrays; ambiguities = false)
#     # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
#     Aqua.test_ambiguities(TaggedAxisArrays)
# end
